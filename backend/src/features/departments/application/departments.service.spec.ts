import { ConflictException, NotFoundException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { Department } from '../domain/entities/department.entity';
import type { DepartmentRepository } from '../domain/repositories/department-repository.interface';
import { DepartmentsService } from './departments.service';
import { UpdateDepartmentDto } from './dto/update-department.dto';

function buildDepartment(overrides: Partial<Department> = {}): Department {
  return {
    id: 'department-1',
    name: 'Engineering',
    description: 'Product engineering',
    ...overrides,
  } as Department;
}

describe('DepartmentsService', () => {
  let service: DepartmentsService;
  let departmentRepository: jest.Mocked<DepartmentRepository>;

  beforeEach(() => {
    departmentRepository = {
      findAll: jest.fn(),
      findById: jest.fn(),
      save: jest.fn(),
      remove: jest.fn(),
    };

    service = new DepartmentsService(departmentRepository);
  });

  describe('create', () => {
    it('saves a new department with the given fields', async () => {
      departmentRepository.save.mockImplementation((department) =>
        Promise.resolve(department),
      );

      const result = await service.create({
        name: 'Engineering',
        description: 'Product engineering',
        headEmployeeId: 'employee-1',
      });

      expect(result.name).toBe('Engineering');
      expect(result.description).toBe('Product engineering');
      expect(result.headEmployeeId).toBe('employee-1');
    });
  });

  describe('update', () => {
    it('applies only the given fields onto the existing department', async () => {
      const existing = buildDepartment({ headEmployeeId: 'employee-1' });
      departmentRepository.findById.mockResolvedValue(existing);
      departmentRepository.save.mockImplementation((department) =>
        Promise.resolve(department),
      );

      const result = await service.update('department-1', {
        name: 'Engineering & Platform',
      });

      expect(result.name).toBe('Engineering & Platform');
      // Fields not present in the DTO are left untouched.
      expect(result.description).toBe('Product engineering');
      expect(result.headEmployeeId).toBe('employee-1');
    });

    it('clears the head employee when explicitly set to null', async () => {
      // Simulates the real HTTP body: class-transformer maps a JSON `null`
      // onto the DTO instance as `null`, not `undefined` — that distinction
      // is what tells Object.assign to clear the field vs. leave it alone.
      const existing = buildDepartment({ headEmployeeId: 'employee-1' });
      departmentRepository.findById.mockResolvedValue(existing);
      departmentRepository.save.mockImplementation((department) =>
        Promise.resolve(department),
      );

      const result = await service.update('department-1', {
        headEmployeeId: null as unknown as string,
      });

      expect(result.headEmployeeId).toBeNull();
    });

    it('throws NotFoundException when the department does not exist', async () => {
      departmentRepository.findById.mockResolvedValue(null);

      await expect(
        service.update('missing-department', { name: 'New Name' }),
      ).rejects.toThrow(NotFoundException);
      expect(departmentRepository.save).not.toHaveBeenCalled();
    });

    it('archiving alone does not wipe the name — regression test for the real request shape', async () => {
      // A plain object literal like `{ isArchived: true }` has no `name` key
      // at all, so it can't reproduce this bug. The real HTTP pipeline runs
      // the body through class-transformer first, and every declared-but-
      // unset field on the resulting instance is an explicit `undefined` own
      // property (`useDefineForClassFields`) — that's what previously made
      // `Object.assign(department, dto)` overwrite `name` with `undefined`.
      const dto = plainToInstance(UpdateDepartmentDto, { isArchived: true });
      expect(Object.keys(dto)).toContain('name');

      const existing = buildDepartment({ headEmployeeId: 'employee-1' });
      departmentRepository.findById.mockResolvedValue(existing);
      departmentRepository.save.mockImplementation((department) =>
        Promise.resolve(department),
      );

      const result = await service.update('department-1', dto);

      expect(result.isArchived).toBe(true);
      expect(result.name).toBe('Engineering');
      expect(result.description).toBe('Product engineering');
      expect(result.headEmployeeId).toBe('employee-1');
    });
  });

  describe('remove', () => {
    it('removes the department when nothing references it', async () => {
      const existing = buildDepartment();
      departmentRepository.findById.mockResolvedValue(existing);
      departmentRepository.remove.mockResolvedValue(undefined);

      await service.remove('department-1');

      expect(departmentRepository.remove).toHaveBeenCalledWith(existing);
    });

    it('throws NotFoundException when the department does not exist', async () => {
      departmentRepository.findById.mockResolvedValue(null);

      await expect(service.remove('missing-department')).rejects.toThrow(
        NotFoundException,
      );
      expect(departmentRepository.remove).not.toHaveBeenCalled();
    });

    it('translates a foreign-key violation into a friendly ConflictException', async () => {
      const existing = buildDepartment();
      departmentRepository.findById.mockResolvedValue(existing);
      departmentRepository.remove.mockRejectedValue({ code: '23503' });

      await expect(service.remove('department-1')).rejects.toThrow(
        ConflictException,
      );
    });

    it('rethrows unrelated errors from the repository', async () => {
      const existing = buildDepartment();
      departmentRepository.findById.mockResolvedValue(existing);
      const unrelatedError = new Error('connection lost');
      departmentRepository.remove.mockRejectedValue(unrelatedError);

      await expect(service.remove('department-1')).rejects.toThrow(
        'connection lost',
      );
    });
  });
});
