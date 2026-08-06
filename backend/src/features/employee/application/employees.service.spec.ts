import {
  ConflictException,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Role } from '../../authentication/domain/entities/role.entity';
import { User } from '../../authentication/domain/entities/user.entity';
import { UserStatus } from '../../authentication/domain/enums/user-status.enum';
import type { RoleRepository } from '../../authentication/domain/repositories/role-repository.interface';
import type { UserRepository } from '../../authentication/domain/repositories/user-repository.interface';
import { Employee } from '../domain/entities/employee.entity';
import { EmploymentStatus } from '../domain/enums/employment-status.enum';
import { EmploymentType } from '../domain/enums/employment-type.enum';
import type { DocumentRepository } from '../domain/repositories/document-repository.interface';
import type { EmployeeRepository } from '../domain/repositories/employee-repository.interface';
import { EmployeesService } from './employees.service';

jest.mock('bcryptjs');

function buildRole(name = 'Employee'): Role {
  return { id: `role-${name}`, name, permissions: [] } as Role;
}

function buildUser(overrides: Partial<User> = {}): User {
  return {
    id: 'user-1',
    email: 'jane.doe@zeracreative.com',
    passwordHash: 'hash',
    roleId: 'role-Employee',
    role: buildRole(),
    status: UserStatus.PENDING_INVITE,
    ...overrides,
  } as User;
}

function buildEmployee(overrides: Partial<Employee> = {}): Employee {
  return {
    id: 'employee-1',
    employeeCode: 'ZC-00001',
    userId: 'user-1',
    user: buildUser({ status: UserStatus.ACTIVE }),
    firstName: 'Jane',
    lastName: 'Doe',
    employmentType: EmploymentType.FULL_TIME,
    employmentStatus: EmploymentStatus.ACTIVE,
    joiningDate: '2026-01-01',
    skills: [],
    certifications: [],
    ...overrides,
  } as Employee;
}

describe('EmployeesService', () => {
  let service: EmployeesService;
  let employeeRepository: jest.Mocked<EmployeeRepository>;
  let userRepository: jest.Mocked<UserRepository>;
  let roleRepository: jest.Mocked<RoleRepository>;
  let documentRepository: jest.Mocked<DocumentRepository>;

  beforeEach(() => {
    employeeRepository = {
      findAll: jest.fn(),
      findById: jest.fn(),
      findByUserId: jest.fn(),
      count: jest.fn(),
      save: jest.fn(),
    };
    userRepository = {
      findByEmail: jest.fn(),
      findById: jest.fn(),
      findAll: jest.fn(),
      save: jest.fn(),
    };
    roleRepository = {
      findByName: jest.fn(),
    };
    documentRepository = {
      findByEmployeeId: jest.fn(),
      findById: jest.fn(),
      save: jest.fn(),
      remove: jest.fn(),
    };

    service = new EmployeesService(
      employeeRepository,
      userRepository,
      roleRepository,
      documentRepository,
    );

    (bcrypt.hash as jest.Mock).mockResolvedValue('hashed-temp-password');
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('invite', () => {
    const dto = {
      companyEmail: 'new.hire@zeracreative.com',
      firstName: 'New',
      lastName: 'Hire',
    };

    it('throws when a user already exists for that email', async () => {
      userRepository.findByEmail.mockResolvedValue(buildUser());

      await expect(service.invite(dto)).rejects.toBeInstanceOf(
        ConflictException,
      );
    });

    it('throws when the default Employee role is not seeded', async () => {
      userRepository.findByEmail.mockResolvedValue(null);
      roleRepository.findByName.mockResolvedValue(null);

      await expect(service.invite(dto)).rejects.toBeInstanceOf(
        InternalServerErrorException,
      );
    });

    it('creates a pending user and employee, returning a temporary password', async () => {
      userRepository.findByEmail.mockResolvedValue(null);
      roleRepository.findByName.mockResolvedValue(buildRole());
      userRepository.save.mockImplementation(
        (user) =>
          Promise.resolve({ ...user, id: 'new-user-id' }) as Promise<User>,
      );
      employeeRepository.count.mockResolvedValue(4);
      employeeRepository.save.mockImplementation((employee) =>
        Promise.resolve({ ...employee, id: 'new-employee-id' }),
      );
      employeeRepository.findById.mockResolvedValue(
        buildEmployee({ id: 'new-employee-id', employeeCode: 'ZC-00005' }),
      );

      const result = await service.invite(dto);

      expect(userRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          email: dto.companyEmail,
          status: UserStatus.PENDING_INVITE,
        }),
      );
      expect(employeeRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ userId: 'new-user-id' }),
      );
      expect(result.temporaryPassword).toHaveLength(12);
      expect(result.employee.employeeCode).toBe('ZC-00005');
    });
  });

  describe('findById', () => {
    it('throws NotFoundException when missing', async () => {
      employeeRepository.findById.mockResolvedValue(null);

      await expect(service.findById('missing')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('returns the mapped employee when found', async () => {
      employeeRepository.findById.mockResolvedValue(buildEmployee());

      const result = await service.findById('employee-1');

      expect(result.fullName).toBe('Jane Doe');
      expect(result.email).toBe('jane.doe@zeracreative.com');
    });
  });

  describe('updateSelf', () => {
    it('throws NotFoundException when the caller has no employee profile', async () => {
      employeeRepository.findByUserId.mockResolvedValue(null);

      await expect(
        service.updateSelf('user-1', { phoneNumber: '123' }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('merges permitted fields and returns the refreshed profile', async () => {
      const existing = buildEmployee();
      employeeRepository.findByUserId.mockResolvedValue(existing);
      employeeRepository.save.mockResolvedValue(existing);
      employeeRepository.findById.mockResolvedValue(
        buildEmployee({ phoneNumber: '+1234567890' }),
      );

      const result = await service.updateSelf('user-1', {
        phoneNumber: '+1234567890',
      });

      expect(employeeRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ phoneNumber: '+1234567890' }),
      );
      expect(result.phoneNumber).toBe('+1234567890');
    });
  });
});
