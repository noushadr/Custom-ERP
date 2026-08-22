import { NotFoundException } from '@nestjs/common';
import { ClientsService } from '../../clients/application/clients.service';
import type { EmployeeRepository } from '../../employee/domain/repositories/employee-repository.interface';
import type { UserRepository } from '../../authentication/domain/repositories/user-repository.interface';
import { RolesService } from '../../authentication/application/roles.service';
import { LeaveService } from '../../leave/application/leave.service';
import { NotificationsService } from '../../notifications/application/notifications.service';
import { TasksService } from '../../tasks/application/tasks.service';
import { AutomationsService } from './automations.service';
import { Automation } from '../domain/entities/automation.entity';
import { AutomationExecutionHistory } from '../domain/entities/automation-execution-history.entity';
import { AutomationRunStatus } from '../domain/enums/automation-run-status.enum';
import { AutomationRunTrigger } from '../domain/enums/automation-run-trigger.enum';
import { AutomationType } from '../domain/enums/automation-type.enum';
import type { AutomationExecutionHistoryRepository } from '../domain/repositories/automation-execution-history-repository.interface';
import type { AutomationRepository } from '../domain/repositories/automation-repository.interface';

function buildAutomation(overrides: Partial<Automation> = {}): Automation {
  return {
    id: 'automation-1',
    type: AutomationType.PROJECT_RENEWAL_REMINDER,
    isActive: false,
    daysBefore: 7,
    updatedByName: null,
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    updatedAt: new Date('2026-01-01T00:00:00.000Z'),
    ...overrides,
  } as Automation;
}

describe('AutomationsService', () => {
  let service: AutomationsService;
  let automationRepository: jest.Mocked<AutomationRepository>;
  let historyRepository: jest.Mocked<AutomationExecutionHistoryRepository>;
  let employeeRepository: jest.Mocked<EmployeeRepository>;
  let userRepository: jest.Mocked<UserRepository>;
  let clientsService: jest.Mocked<ClientsService>;
  let tasksService: jest.Mocked<TasksService>;
  let leaveService: jest.Mocked<LeaveService>;
  let notificationsService: jest.Mocked<NotificationsService>;
  let rolesService: jest.Mocked<RolesService>;

  beforeEach(() => {
    automationRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findByType: jest.fn(),
      save: jest.fn((a) => Promise.resolve(a)),
    };
    historyRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      save: jest.fn((entry) =>
        Promise.resolve({
          ...entry,
          id: entry.id ?? 'history-1',
          createdAt: entry.createdAt ?? new Date('2026-01-01T00:00:00.000Z'),
          updatedAt: new Date('2026-01-01T00:00:00.000Z'),
        } as AutomationExecutionHistory),
      ),
    };
    employeeRepository = {
      findByUserId: jest.fn().mockResolvedValue(null),
    } as unknown as jest.Mocked<EmployeeRepository>;
    userRepository = {
      findById: jest
        .fn()
        .mockResolvedValue({ id: 'admin-1', email: 'admin@zeracreative.com' }),
    } as unknown as jest.Mocked<UserRepository>;
    clientsService = {
      getProjectsNeedingRenewalReminder: jest.fn().mockResolvedValue([]),
      markRenewalReminderSent: jest.fn().mockResolvedValue(undefined),
    } as unknown as jest.Mocked<ClientsService>;
    tasksService = {
      getTasksNeedingDeadlineReminder: jest.fn().mockResolvedValue([]),
      markDeadlineReminderSent: jest.fn().mockResolvedValue(undefined),
    } as unknown as jest.Mocked<TasksService>;
    leaveService = {
      getResetStatus: jest
        .fn()
        .mockResolvedValue({ year: 2026, isInitialized: true }),
      runAnnualReset: jest
        .fn()
        .mockResolvedValue({ year: 2026, balancesCreated: 0 }),
    } as unknown as jest.Mocked<LeaveService>;
    notificationsService = {
      create: jest.fn().mockResolvedValue(undefined),
    } as unknown as jest.Mocked<NotificationsService>;
    rolesService = {
      findUsersWithPermission: jest.fn().mockResolvedValue([]),
    } as unknown as jest.Mocked<RolesService>;

    service = new AutomationsService(
      automationRepository,
      historyRepository,
      employeeRepository,
      userRepository,
      clientsService,
      tasksService,
      leaveService,
      notificationsService,
      rolesService,
    );
  });

  describe('onModuleInit', () => {
    it('seeds exactly one row per AutomationType when none exist', async () => {
      await service.onModuleInit();

      expect(automationRepository.save).toHaveBeenCalledTimes(3);
      const savedTypes = automationRepository.save.mock.calls.map(
        (call) => call[0].type,
      );
      expect(savedTypes.sort()).toEqual(
        Object.values(AutomationType).sort(),
      );
    });

    it('defaults annual leave reset to a null daysBefore, others to 7', async () => {
      await service.onModuleInit();

      const saved = automationRepository.save.mock.calls.map((c) => c[0]);
      const leaveReset = saved.find(
        (a) => a.type === AutomationType.ANNUAL_LEAVE_RESET,
      );
      const renewal = saved.find(
        (a) => a.type === AutomationType.PROJECT_RENEWAL_REMINDER,
      );
      expect(leaveReset?.daysBefore).toBeNull();
      expect(renewal?.daysBefore).toBe(7);
    });

    it('does not re-seed rows that already exist', async () => {
      automationRepository.findAll.mockResolvedValue([
        buildAutomation({ type: AutomationType.PROJECT_RENEWAL_REMINDER }),
        buildAutomation({ type: AutomationType.TASK_DEADLINE_REMINDER }),
        buildAutomation({ type: AutomationType.ANNUAL_LEAVE_RESET }),
      ]);

      await service.onModuleInit();

      expect(automationRepository.save).not.toHaveBeenCalled();
    });
  });

  describe('updateAutomation', () => {
    it('updates isActive and daysBefore, and snapshots the actor name', async () => {
      automationRepository.findByType.mockResolvedValue(buildAutomation());
      employeeRepository.findByUserId.mockResolvedValue({
        firstName: 'Jane',
        lastName: 'Admin',
      } as never);

      const result = await service.updateAutomation(
        AutomationType.PROJECT_RENEWAL_REMINDER,
        { isActive: true, daysBefore: 3 },
        'admin-1',
      );

      expect(result.isActive).toBe(true);
      expect(result.daysBefore).toBe(3);
      expect(result.updatedByName).toBe('Jane Admin');
    });

    it('throws NotFoundException for an unknown type', async () => {
      automationRepository.findByType.mockResolvedValue(null);
      await expect(
        service.updateAutomation(
          AutomationType.PROJECT_RENEWAL_REMINDER,
          { isActive: true },
          'admin-1',
        ),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('runAutomation — project renewal reminder', () => {
    it('notifies every clients.manage holder for each matching project, then marks it sent', async () => {
      automationRepository.findByType.mockResolvedValue(
        buildAutomation({ daysBefore: 5 }),
      );
      clientsService.getProjectsNeedingRenewalReminder.mockResolvedValue([
        { id: 'p1', name: 'Retainer A', clientName: 'Acme', renewalDate: '2026-08-27' },
      ]);
      rolesService.findUsersWithPermission.mockResolvedValue([
        { id: 'admin-1' },
        { id: 'admin-2' },
      ]);

      const result = await service.runAutomation(
        AutomationType.PROJECT_RENEWAL_REMINDER,
        AutomationRunTrigger.MANUAL,
      );

      expect(clientsService.getProjectsNeedingRenewalReminder).toHaveBeenCalledWith(5);
      expect(notificationsService.create).toHaveBeenCalledTimes(2);
      expect(clientsService.markRenewalReminderSent).toHaveBeenCalledWith('p1');
      expect(result.status).toBe(AutomationRunStatus.SUCCESS);
      expect(result.itemsProcessed).toBe(1);
      expect(result.notificationsCreated).toBe(2);
    });

    it('is a no-op when nothing matches', async () => {
      automationRepository.findByType.mockResolvedValue(buildAutomation());
      clientsService.getProjectsNeedingRenewalReminder.mockResolvedValue([]);

      const result = await service.runAutomation(
        AutomationType.PROJECT_RENEWAL_REMINDER,
        AutomationRunTrigger.CRON,
      );

      expect(notificationsService.create).not.toHaveBeenCalled();
      expect(clientsService.markRenewalReminderSent).not.toHaveBeenCalled();
      expect(result.itemsProcessed).toBe(0);
      expect(result.notificationsCreated).toBe(0);
    });
  });

  describe('runAutomation — task deadline reminder', () => {
    it("notifies each task's own assignee directly, then marks it sent", async () => {
      automationRepository.findByType.mockResolvedValue(
        buildAutomation({
          type: AutomationType.TASK_DEADLINE_REMINDER,
          daysBefore: 2,
        }),
      );
      tasksService.getTasksNeedingDeadlineReminder.mockResolvedValue([
        { id: 't1', title: 'Design homepage', assigneeUserId: 'user-1' },
      ]);

      const result = await service.runAutomation(
        AutomationType.TASK_DEADLINE_REMINDER,
        AutomationRunTrigger.MANUAL,
      );

      expect(tasksService.getTasksNeedingDeadlineReminder).toHaveBeenCalledWith(2);
      expect(notificationsService.create).toHaveBeenCalledWith(
        expect.objectContaining({ recipientUserId: 'user-1' }),
      );
      expect(tasksService.markDeadlineReminderSent).toHaveBeenCalledWith('t1');
      expect(result.itemsProcessed).toBe(1);
      expect(result.notificationsCreated).toBe(1);
    });
  });

  describe('runAutomation — annual leave reset', () => {
    it('is a no-op once the year is already initialized', async () => {
      automationRepository.findByType.mockResolvedValue(
        buildAutomation({ type: AutomationType.ANNUAL_LEAVE_RESET, daysBefore: null }),
      );
      leaveService.getResetStatus.mockResolvedValue({
        year: 2026,
        isInitialized: true,
      });

      const result = await service.runAutomation(
        AutomationType.ANNUAL_LEAVE_RESET,
        AutomationRunTrigger.CRON,
      );

      expect(leaveService.runAnnualReset).not.toHaveBeenCalled();
      expect(result.itemsProcessed).toBe(0);
    });

    it('runs the reset and notifies every leave.manage holder when not yet initialized', async () => {
      automationRepository.findByType.mockResolvedValue(
        buildAutomation({ type: AutomationType.ANNUAL_LEAVE_RESET, daysBefore: null }),
      );
      leaveService.getResetStatus.mockResolvedValue({
        year: 2026,
        isInitialized: false,
      });
      leaveService.runAnnualReset.mockResolvedValue({
        year: 2026,
        balancesCreated: 42,
      });
      rolesService.findUsersWithPermission.mockResolvedValue([{ id: 'hr-1' }]);

      const result = await service.runAutomation(
        AutomationType.ANNUAL_LEAVE_RESET,
        AutomationRunTrigger.CRON,
      );

      expect(rolesService.findUsersWithPermission).toHaveBeenCalledWith('leave.manage');
      expect(notificationsService.create).toHaveBeenCalledWith(
        expect.objectContaining({ recipientUserId: 'hr-1' }),
      );
      expect(result.itemsProcessed).toBe(42);
      expect(result.notificationsCreated).toBe(1);
    });
  });

  describe('runAutomation — error handling', () => {
    it('records a failed run without throwing, when a handler errors', async () => {
      automationRepository.findByType.mockResolvedValue(buildAutomation());
      clientsService.getProjectsNeedingRenewalReminder.mockRejectedValue(
        new Error('DB unavailable'),
      );

      const result = await service.runAutomation(
        AutomationType.PROJECT_RENEWAL_REMINDER,
        AutomationRunTrigger.CRON,
      );

      expect(result.status).toBe(AutomationRunStatus.ERROR);
      expect(result.errorMessage).toBe('DB unavailable');
      expect(historyRepository.save).toHaveBeenCalledTimes(1);
    });

    it('throws NotFoundException for an unknown type', async () => {
      automationRepository.findByType.mockResolvedValue(null);
      await expect(
        service.runAutomation(
          AutomationType.PROJECT_RENEWAL_REMINDER,
          AutomationRunTrigger.MANUAL,
        ),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('handleDailyAutomationsCheck', () => {
    it('only runs automations that are active', async () => {
      automationRepository.findAll.mockResolvedValue([
        buildAutomation({
          type: AutomationType.PROJECT_RENEWAL_REMINDER,
          isActive: true,
        }),
        buildAutomation({
          type: AutomationType.TASK_DEADLINE_REMINDER,
          isActive: false,
        }),
      ]);
      automationRepository.findByType.mockImplementation((type) =>
        Promise.resolve(buildAutomation({ type, isActive: true })),
      );

      await service.handleDailyAutomationsCheck();

      expect(clientsService.getProjectsNeedingRenewalReminder).toHaveBeenCalled();
      expect(tasksService.getTasksNeedingDeadlineReminder).not.toHaveBeenCalled();
    });
  });

  describe('getExecutionHistory', () => {
    it('passes the type filter through to the repository', async () => {
      await service.getExecutionHistory(AutomationType.ANNUAL_LEAVE_RESET);
      expect(historyRepository.findAll).toHaveBeenCalledWith(
        AutomationType.ANNUAL_LEAVE_RESET,
      );
    });
  });
});
