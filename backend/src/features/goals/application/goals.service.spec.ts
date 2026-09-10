import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Employee } from '../../employee/domain/entities/employee.entity';
import { EmploymentStatus } from '../../employee/domain/enums/employment-status.enum';
import type { EmployeeRepository } from '../../employee/domain/repositories/employee-repository.interface';
import type { UserRepository } from '../../authentication/domain/repositories/user-repository.interface';
import { EmployeeGoal } from '../domain/entities/employee-goal.entity';
import type { GoalRepository } from '../domain/repositories/goal-repository.interface';
import { GoalsService } from './goals.service';

function buildEmployee(overrides: Partial<Employee> = {}): Employee {
  return {
    id: 'employee-1',
    userId: 'user-employee-1',
    firstName: 'Babar',
    lastName: 'Hussain',
    profilePhotoUrl: undefined,
    employmentStatus: EmploymentStatus.ACTIVE,
    ...overrides,
  } as Employee;
}

function buildGoal(overrides: Partial<EmployeeGoal> = {}): EmployeeGoal {
  return {
    id: 'goal-1',
    employeeId: 'employee-1',
    employee: buildEmployee(),
    title: 'English speaking',
    description: null,
    achievementPercentage: 0,
    archived: false,
    createdByUserId: 'admin-1',
    createdByName: 'Noushad Ranani',
    createdAt: new Date('2026-09-08T00:00:00Z'),
    ...overrides,
  } as EmployeeGoal;
}

describe('GoalsService', () => {
  let service: GoalsService;
  let goalRepository: jest.Mocked<GoalRepository>;
  let employeeRepository: jest.Mocked<EmployeeRepository>;
  let userRepository: jest.Mocked<UserRepository>;

  beforeEach(() => {
    goalRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      findByEmployeeId: jest.fn().mockResolvedValue([]),
      save: jest.fn((goal) => Promise.resolve(goal)),
      saveMany: jest.fn((goals) =>
        Promise.resolve(
          goals.map((g, i) => ({ ...g, id: g.id ?? `goal-${i + 1}` })),
        ),
      ),
    };
    employeeRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      findByUserId: jest.fn(),
      findByReportingManagerId: jest.fn().mockResolvedValue([]),
      count: jest.fn(),
      save: jest.fn(),
    };
    userRepository = {
      findByEmail: jest.fn(),
      findById: jest
        .fn()
        .mockResolvedValue({ id: 'admin-1', email: 'admin@zeracreative.com' }),
      findAll: jest.fn(),
      save: jest.fn(),
    };

    service = new GoalsService(goalRepository, employeeRepository, userRepository);
  });

  describe('createForEmployee', () => {
    it('creates a goal with the resolved actor name', async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'admin-1', firstName: 'Noushad', lastName: 'Ranani' }),
      );
      goalRepository.findById.mockResolvedValue(buildGoal());

      const result = await service.createForEmployee(
        { employeeId: 'employee-1', title: 'English speaking' },
        'admin-1',
      );

      expect(goalRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          employeeId: 'employee-1',
          title: 'English speaking',
          createdByName: 'Noushad Ranani',
        }),
      );
      expect(result.title).toBe('English speaking');
    });
  });

  describe('createForMyDirectReport', () => {
    it("throws ForbiddenException when the target isn't a direct report", async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'manager-1' }),
      );
      employeeRepository.findById.mockResolvedValue(
        buildEmployee({ id: 'employee-1', reportingManagerId: 'someone-else' }),
      );

      await expect(
        service.createForMyDirectReport('user-1', {
          employeeId: 'employee-1',
          title: 'English speaking',
        }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('creates a goal for an actual direct report', async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'manager-1', firstName: 'Bilal', lastName: 'Rathore' }),
      );
      employeeRepository.findById.mockResolvedValue(
        buildEmployee({ id: 'employee-1', reportingManagerId: 'manager-1' }),
      );
      goalRepository.findById.mockResolvedValue(buildGoal());

      const result = await service.createForMyDirectReport('user-1', {
        employeeId: 'employee-1',
        title: 'English speaking',
      });

      expect(goalRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ createdByName: 'Bilal Rathore' }),
      );
      expect(result.employeeId).toBe('employee-1');
    });
  });

  describe('bulkAssignToDepartment', () => {
    it('creates one goal per active employee in the department, skipping others', async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'admin-1' }),
      );
      employeeRepository.findAll.mockResolvedValue([
        buildEmployee({
          id: 'seo-1',
          departmentId: 'dept-seo',
          employmentStatus: EmploymentStatus.ACTIVE,
        }),
        buildEmployee({
          id: 'seo-2',
          departmentId: 'dept-seo',
          employmentStatus: EmploymentStatus.ACTIVE,
        }),
        buildEmployee({
          id: 'seo-resigned',
          departmentId: 'dept-seo',
          employmentStatus: EmploymentStatus.RESIGNED,
        }),
        buildEmployee({ id: 'other-dept', departmentId: 'dept-sales' }),
      ]);
      goalRepository.findById.mockImplementation((id) =>
        Promise.resolve(buildGoal({ id, employeeId: id.replace('goal-', 'seo-') })),
      );

      const result = await service.bulkAssignToDepartment(
        { departmentId: 'dept-seo', title: 'English speaking' },
        'admin-1',
      );

      expect(goalRepository.saveMany).toHaveBeenCalledWith([
        expect.objectContaining({ employeeId: 'seo-1', title: 'English speaking' }),
        expect.objectContaining({ employeeId: 'seo-2', title: 'English speaking' }),
      ]);
      expect(result).toHaveLength(2);
    });
  });

  describe('update', () => {
    it('throws NotFoundException when the goal is missing', async () => {
      goalRepository.findById.mockResolvedValue(null);

      await expect(
        service.update('missing', { title: 'x' }, 'admin-1', {
          requireOwnDirectReport: false,
        }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it("throws ForbiddenException when a manager edits someone else's report's goal", async () => {
      goalRepository.findById.mockResolvedValue(
        buildGoal({ employee: buildEmployee({ reportingManagerId: 'someone-else' }) }),
      );
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'manager-1' }),
      );

      await expect(
        service.update('goal-1', { title: 'x' }, 'user-1', {
          requireOwnDirectReport: true,
        }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('updates the title/description when authorized', async () => {
      goalRepository.findById.mockResolvedValue(buildGoal());

      const result = await service.update(
        'goal-1',
        { title: 'Fluent English', description: 'Practice daily' },
        'admin-1',
        { requireOwnDirectReport: false },
      );

      expect(result.title).toBe('Fluent English');
      expect(result.description).toBe('Practice daily');
    });

    it('lets Admin/HR set the achievement percentage', async () => {
      goalRepository.findById.mockResolvedValue(buildGoal());

      const result = await service.update(
        'goal-1',
        { achievementPercentage: 75 },
        'admin-1',
        { requireOwnDirectReport: false },
      );

      expect(result.achievementPercentage).toBe(75);
    });

    it("ignores the achievement percentage on a Team Lead's own-report edit", async () => {
      goalRepository.findById.mockResolvedValue(
        buildGoal({
          employee: buildEmployee({ reportingManagerId: 'manager-1' }),
        }),
      );
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'manager-1' }),
      );

      const result = await service.update(
        'goal-1',
        { achievementPercentage: 90 },
        'user-1',
        { requireOwnDirectReport: true },
      );

      expect(result.achievementPercentage).toBe(0);
    });
  });

  describe('archive', () => {
    it('soft-archives the goal instead of removing it', async () => {
      const goal = buildGoal();
      goalRepository.findById.mockResolvedValue(goal);

      await service.archive('goal-1', 'admin-1', {
        requireOwnDirectReport: false,
      });

      expect(goalRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ archived: true }),
      );
    });

    it("throws ForbiddenException when a manager archives someone else's report's goal", async () => {
      goalRepository.findById.mockResolvedValue(
        buildGoal({ employee: buildEmployee({ reportingManagerId: 'someone-else' }) }),
      );
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'manager-1' }),
      );

      await expect(
        service.archive('goal-1', 'user-1', { requireOwnDirectReport: true }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });
  });

  describe('findForMyTeam', () => {
    it("only returns goals belonging to this manager's direct reports", async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'manager-1' }),
      );
      employeeRepository.findByReportingManagerId.mockResolvedValue([
        buildEmployee({ id: 'report-1' }),
      ]);
      goalRepository.findAll.mockResolvedValue([
        buildGoal({ id: 'goal-mine', employeeId: 'report-1' }),
        buildGoal({ id: 'goal-not-mine', employeeId: 'someone-else' }),
      ]);

      const result = await service.findForMyTeam('user-1');

      expect(result.map((g) => g.id)).toEqual(['goal-mine']);
    });
  });

  describe('findMine', () => {
    it('returns an empty list when the caller has no employee profile', async () => {
      employeeRepository.findByUserId.mockResolvedValue(null);

      const result = await service.findMine('user-1');

      expect(result).toEqual([]);
    });
  });
});
