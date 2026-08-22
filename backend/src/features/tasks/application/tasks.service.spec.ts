import { ForbiddenException, NotFoundException } from '@nestjs/common';
import type { UserRepository } from '../../authentication/domain/repositories/user-repository.interface';
import { Department } from '../../departments/domain/entities/department.entity';
import type { DepartmentRepository } from '../../departments/domain/repositories/department-repository.interface';
import { Employee } from '../../employee/domain/entities/employee.entity';
import type { EmployeeRepository } from '../../employee/domain/repositories/employee-repository.interface';
import type { NotificationsService } from '../../notifications/application/notifications.service';
import { Task } from '../domain/entities/task.entity';
import { TaskAuditLog } from '../domain/entities/task-audit-log.entity';
import { TaskComment } from '../domain/entities/task-comment.entity';
import { TaskPriority } from '../domain/enums/task-priority.enum';
import { TaskStatus } from '../domain/enums/task-status.enum';
import type { TaskAuditLogRepository } from '../domain/repositories/task-audit-log-repository.interface';
import type { TaskCommentRepository } from '../domain/repositories/task-comment-repository.interface';
import type { TaskRepository } from '../domain/repositories/task-repository.interface';
import { TasksService } from './tasks.service';

function buildDepartment(overrides: Partial<Department> = {}): Department {
  return { id: 'dept-1', name: 'Engineering', ...overrides } as Department;
}

function buildEmployee(overrides: Partial<Employee> = {}): Employee {
  return {
    id: 'employee-1',
    userId: 'user-1',
    firstName: 'Jane',
    lastName: 'Doe',
    departmentId: 'dept-1',
    department: buildDepartment(),
    profilePhotoUrl: undefined,
    ...overrides,
  } as Employee;
}

function buildTask(overrides: Partial<Task> = {}): Task {
  return {
    id: 'task-1',
    title: 'Write report',
    description: null,
    assigneeEmployeeId: 'employee-1',
    assignee: buildEmployee(),
    assignedByUserId: 'manager-user-1',
    assignedByName: 'Manager Person',
    assignedByPhotoUrl: null,
    priority: TaskPriority.MEDIUM,
    dueDate: '2026-12-01',
    status: TaskStatus.TODO,
    completedAt: null,
    projectId: null,
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    updatedAt: new Date('2026-01-01T00:00:00.000Z'),
    ...overrides,
  } as Task;
}

describe('TasksService', () => {
  let service: TasksService;
  let taskRepository: jest.Mocked<TaskRepository>;
  let commentRepository: jest.Mocked<TaskCommentRepository>;
  let auditLogRepository: jest.Mocked<TaskAuditLogRepository>;
  let employeeRepository: jest.Mocked<EmployeeRepository>;
  let departmentRepository: jest.Mocked<DepartmentRepository>;
  let userRepository: jest.Mocked<UserRepository>;
  let notificationsService: jest.Mocked<NotificationsService>;

  beforeEach(() => {
    taskRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      findByProjectId: jest.fn().mockResolvedValue([]),
      save: jest.fn((item) => Promise.resolve(item)),
    };
    commentRepository = {
      findByTaskId: jest.fn().mockResolvedValue([]),
      save: jest.fn((item) =>
        Promise.resolve({
          ...item,
          createdAt: item.createdAt ?? new Date('2026-01-01T00:00:00.000Z'),
        }),
      ),
    };
    auditLogRepository = {
      findByTaskId: jest.fn().mockResolvedValue([]),
      save: jest.fn((item) => Promise.resolve(item)),
    };
    employeeRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      findByUserId: jest.fn(),
      findByReportingManagerId: jest.fn(),
      count: jest.fn(),
      save: jest.fn(),
    };
    departmentRepository = {
      findAll: jest.fn().mockResolvedValue([buildDepartment()]),
      findById: jest.fn(),
      save: jest.fn(),
      remove: jest.fn(),
    };
    userRepository = {
      findByEmail: jest.fn(),
      findById: jest.fn(),
      findAll: jest.fn(),
      save: jest.fn(),
    };
    notificationsService = {
      create: jest.fn(),
    } as unknown as jest.Mocked<NotificationsService>;

    service = new TasksService(
      taskRepository,
      commentRepository,
      auditLogRepository,
      employeeRepository,
      departmentRepository,
      userRepository,
      notificationsService,
    );
  });

  describe('getMyTasks / getTasksAssignedByMe / getTeamTasks', () => {
    it('getMyTasks returns only tasks assigned to the caller', async () => {
      taskRepository.findAll.mockResolvedValue([
        buildTask({ id: 'task-1', assigneeEmployeeId: 'employee-1' }),
        buildTask({ id: 'task-2', assigneeEmployeeId: 'employee-2' }),
      ]);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'employee-1' }),
      );

      const result = await service.getMyTasks('user-1');

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('task-1');
    });

    it('getTasksAssignedByMe returns only tasks the caller created', async () => {
      taskRepository.findAll.mockResolvedValue([
        buildTask({ id: 'task-1', assignedByUserId: 'manager-1' }),
        buildTask({ id: 'task-2', assignedByUserId: 'manager-2' }),
      ]);

      const result = await service.getTasksAssignedByMe('manager-1');

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('task-1');
    });

    it('getTeamTasks returns everything for a tasks.manage override', async () => {
      taskRepository.findAll.mockResolvedValue([
        buildTask({ id: 'task-1' }),
        buildTask({ id: 'task-2' }),
      ]);

      const result = await service.getTeamTasks('admin-1', true);

      expect(result).toHaveLength(2);
      expect(employeeRepository.findByUserId).not.toHaveBeenCalled();
    });

    it('getTeamTasks returns only tasks in a department the caller heads', async () => {
      taskRepository.findAll.mockResolvedValue([
        buildTask({
          id: 'task-1',
          assignee: buildEmployee({ departmentId: 'dept-1' }),
        }),
        buildTask({
          id: 'task-2',
          assignee: buildEmployee({
            id: 'employee-2',
            departmentId: 'dept-2',
          }),
        }),
      ]);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'head-1' }),
      );
      departmentRepository.findAll.mockResolvedValue([
        buildDepartment({ id: 'dept-1', headEmployeeId: 'head-1' }),
        buildDepartment({ id: 'dept-2', headEmployeeId: 'someone-else' }),
      ]);

      const result = await service.getTeamTasks('head-user-1', false);

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('task-1');
    });

    it('getTeamTasks returns nothing for a caller who heads no department', async () => {
      taskRepository.findAll.mockResolvedValue([buildTask()]);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'plain-employee' }),
      );
      departmentRepository.findAll.mockResolvedValue([
        buildDepartment({ headEmployeeId: 'someone-else' }),
      ]);

      const result = await service.getTeamTasks('plain-user-1', false);

      expect(result).toHaveLength(0);
    });
  });

  describe('getTaskForActor', () => {
    it('throws NotFoundException when missing', async () => {
      taskRepository.findById.mockResolvedValue(null);

      await expect(
        service.getTaskForActor('missing', 'user-1', false),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('is visible to the assignee', async () => {
      taskRepository.findById.mockResolvedValue(buildTask());
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'employee-1' }),
      );

      const result = await service.getTaskForActor('task-1', 'user-1', false);

      expect(result.id).toBe('task-1');
    });

    it('is visible to the assigner', async () => {
      taskRepository.findById.mockResolvedValue(
        buildTask({ assignedByUserId: 'manager-1' }),
      );
      employeeRepository.findByUserId.mockResolvedValue(null);

      const result = await service.getTaskForActor(
        'task-1',
        'manager-1',
        false,
      );

      expect(result.id).toBe('task-1');
    });

    it('is visible to the department head of the assignee', async () => {
      taskRepository.findById.mockResolvedValue(
        buildTask({ assignee: buildEmployee({ departmentId: 'dept-1' }) }),
      );
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'head-1' }),
      );
      departmentRepository.findAll.mockResolvedValue([
        buildDepartment({ id: 'dept-1', headEmployeeId: 'head-1' }),
      ]);

      const result = await service.getTaskForActor(
        'task-1',
        'head-user-1',
        false,
      );

      expect(result.id).toBe('task-1');
    });

    it('is forbidden for an unrelated employee', async () => {
      taskRepository.findById.mockResolvedValue(buildTask());
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'stranger-1', departmentId: 'dept-2' }),
      );
      departmentRepository.findAll.mockResolvedValue([
        buildDepartment({ id: 'dept-1', headEmployeeId: null }),
      ]);

      await expect(
        service.getTaskForActor('task-1', 'stranger-user-1', false),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });
  });

  describe('createTask', () => {
    it('lets a tasks.manage override assign to anyone', async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ firstName: 'Admin', lastName: 'Person' }),
      );
      employeeRepository.findById.mockResolvedValue(
        buildEmployee({ id: 'employee-2' }),
      );
      taskRepository.findById.mockImplementation((id) =>
        Promise.resolve(buildTask({ id })),
      );

      const result = await service.createTask(
        {
          title: 'New task',
          assigneeEmployeeId: 'employee-2',
          dueDate: '2026-12-01',
        },
        'admin-user-1',
        true,
      );

      expect(result).toBeDefined();
      expect(taskRepository.save).toHaveBeenCalledTimes(1);
      expect(auditLogRepository.save).toHaveBeenCalledTimes(1);
      const savedLog = auditLogRepository.save.mock.calls[0][0];
      expect(savedLog.fieldLabel).toBe('Created');
    });

    it("snapshots the assigner's current photo onto the task", async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({
          firstName: 'Admin',
          lastName: 'Person',
          profilePhotoUrl: '/uploads/avatars/admin.jpg',
        }),
      );
      employeeRepository.findById.mockResolvedValue(
        buildEmployee({ id: 'employee-2' }),
      );
      taskRepository.findById.mockImplementation((id) =>
        Promise.resolve(buildTask({ id })),
      );

      await service.createTask(
        {
          title: 'New task',
          assigneeEmployeeId: 'employee-2',
          dueDate: '2026-12-01',
        },
        'admin-user-1',
        true,
      );

      const savedTask = taskRepository.save.mock.calls[0][0];
      expect(savedTask.assignedByPhotoUrl).toBe('/uploads/avatars/admin.jpg');
    });

    it('lets a department head assign within their department', async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'head-1', firstName: 'Head', lastName: 'Person' }),
      );
      employeeRepository.findById.mockResolvedValue(
        buildEmployee({ id: 'employee-2', departmentId: 'dept-1' }),
      );
      departmentRepository.findAll.mockResolvedValue([
        buildDepartment({ id: 'dept-1', headEmployeeId: 'head-1' }),
      ]);
      taskRepository.findById.mockImplementation((id) =>
        Promise.resolve(buildTask({ id })),
      );

      const result = await service.createTask(
        {
          title: 'New task',
          assigneeEmployeeId: 'employee-2',
          dueDate: '2026-12-01',
        },
        'head-user-1',
        false,
      );

      expect(result).toBeDefined();
    });

    it('rejects a department head assigning outside their department', async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'head-1' }),
      );
      employeeRepository.findById.mockResolvedValue(
        buildEmployee({ id: 'employee-2', departmentId: 'dept-2' }),
      );
      departmentRepository.findAll.mockResolvedValue([
        buildDepartment({ id: 'dept-1', headEmployeeId: 'head-1' }),
        buildDepartment({ id: 'dept-2', headEmployeeId: 'someone-else' }),
      ]);

      await expect(
        service.createTask(
          {
            title: 'New task',
            assigneeEmployeeId: 'employee-2',
            dueDate: '2026-12-01',
          },
          'head-user-1',
          false,
        ),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(taskRepository.save).not.toHaveBeenCalled();
    });

    it('rejects a plain employee entirely', async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'plain-1' }),
      );
      departmentRepository.findAll.mockResolvedValue([
        buildDepartment({ headEmployeeId: 'someone-else' }),
      ]);

      await expect(
        service.createTask(
          {
            title: 'New task',
            assigneeEmployeeId: 'employee-2',
            dueDate: '2026-12-01',
          },
          'plain-user-1',
          false,
        ),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });
  });

  describe('updateStatus', () => {
    it('lets the assignee change their own task status', async () => {
      const task = buildTask({ status: TaskStatus.TODO });
      taskRepository.findById.mockResolvedValue(task);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'employee-1' }),
      );

      const result = await service.updateStatus(
        'task-1',
        { status: TaskStatus.IN_PROGRESS },
        'user-1',
        false,
      );

      expect(result.status).toBe(TaskStatus.IN_PROGRESS);
    });

    it('stamps completedAt when moved to completed and clears it otherwise', async () => {
      const task = buildTask({ status: TaskStatus.IN_PROGRESS });
      taskRepository.findById.mockResolvedValue(task);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'employee-1' }),
      );

      await service.updateStatus(
        'task-1',
        { status: TaskStatus.COMPLETED },
        'user-1',
        false,
      );

      expect(task.completedAt).not.toBeNull();

      await service.updateStatus(
        'task-1',
        { status: TaskStatus.IN_PROGRESS },
        'user-1',
        false,
      );

      expect(task.completedAt).toBeNull();
    });

    it('lets the assigner change status', async () => {
      const task = buildTask({ assignedByUserId: 'manager-1' });
      taskRepository.findById.mockResolvedValue(task);
      employeeRepository.findByUserId.mockResolvedValue(null);

      const result = await service.updateStatus(
        'task-1',
        { status: TaskStatus.CANCELLED },
        'manager-1',
        false,
      );

      expect(result.status).toBe(TaskStatus.CANCELLED);
    });

    it('rejects an unrelated employee', async () => {
      taskRepository.findById.mockResolvedValue(buildTask());
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'stranger-1', departmentId: 'dept-2' }),
      );
      departmentRepository.findAll.mockResolvedValue([
        buildDepartment({ id: 'dept-1', headEmployeeId: null }),
      ]);

      await expect(
        service.updateStatus(
          'task-1',
          { status: TaskStatus.CANCELLED },
          'stranger-user-1',
          false,
        ),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });
  });

  describe('comments', () => {
    it('lets a viewer with access add a comment', async () => {
      taskRepository.findById.mockResolvedValue(buildTask());
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'employee-1' }),
      );

      const result = await service.addComment(
        'task-1',
        { body: 'Looks good' },
        'user-1',
        false,
      );

      expect(result.body).toBe('Looks good');
      expect(commentRepository.save).toHaveBeenCalledTimes(1);
    });

    it('rejects a comment from someone without view access', async () => {
      taskRepository.findById.mockResolvedValue(buildTask());
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'stranger-1', departmentId: 'dept-2' }),
      );
      departmentRepository.findAll.mockResolvedValue([
        buildDepartment({ id: 'dept-1', headEmployeeId: null }),
      ]);

      await expect(
        service.addComment(
          'task-1',
          { body: 'Hi' },
          'stranger-user-1',
          false,
        ),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });
  });

  describe('history', () => {
    it('records a "Created" entry, and a "Status" entry on transition', async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ firstName: 'Admin', lastName: 'Person' }),
      );
      employeeRepository.findById.mockResolvedValue(
        buildEmployee({ id: 'employee-2' }),
      );
      const created = buildTask({ id: 'task-9' });
      taskRepository.findById.mockImplementation((id) =>
        Promise.resolve({ ...created, id }),
      );

      await service.createTask(
        {
          title: 'New task',
          assigneeEmployeeId: 'employee-2',
          dueDate: '2026-12-01',
        },
        'admin-user-1',
        true,
      );

      await service.updateStatus(
        'task-9',
        { status: TaskStatus.IN_PROGRESS },
        'admin-user-1',
        true,
      );

      expect(auditLogRepository.save).toHaveBeenCalledTimes(2);
      const labels = auditLogRepository.save.mock.calls.map(
        (call) => call[0].fieldLabel,
      );
      expect(labels).toEqual(['Created', 'Status']);
    });
  });

  describe('getTasksByProject', () => {
    it("returns a project's linked tasks", async () => {
      taskRepository.findByProjectId.mockResolvedValue([
        buildTask({ id: 'task-1', projectId: 'project-1' }),
      ]);

      const result = await service.getTasksByProject('project-1');

      expect(taskRepository.findByProjectId).toHaveBeenCalledWith(
        'project-1',
      );
      expect(result).toHaveLength(1);
      expect(result[0].projectId).toBe('project-1');
    });
  });

  describe('project linking', () => {
    it('links a new task to a project on create', async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ firstName: 'Admin', lastName: 'Person' }),
      );
      employeeRepository.findById.mockResolvedValue(
        buildEmployee({ id: 'employee-2' }),
      );
      taskRepository.findById.mockImplementation((id) =>
        Promise.resolve(buildTask({ id, projectId: 'project-1' })),
      );

      const result = await service.createTask(
        {
          title: 'New task',
          assigneeEmployeeId: 'employee-2',
          dueDate: '2026-12-01',
          projectId: 'project-1',
        },
        'admin-user-1',
        true,
      );

      const savedTask = taskRepository.save.mock.calls[0][0];
      expect(savedTask.projectId).toBe('project-1');
      expect(result.projectId).toBe('project-1');
    });

    it('links an existing task to a project on update', async () => {
      const task = buildTask({ projectId: null });
      taskRepository.findById.mockResolvedValue(task);

      await service.updateTask(
        'task-1',
        { projectId: 'project-1' },
        'manager-user-1',
        false,
      );

      expect(task.projectId).toBe('project-1');
    });
  });

  describe('getTasksNeedingDeadlineReminder', () => {
    function isoDaysFromNow(days: number): string {
      const date = new Date();
      date.setDate(date.getDate() + days);
      return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
    }

    it('matches an open task due within the window', async () => {
      taskRepository.findAll.mockResolvedValue([
        buildTask({ status: TaskStatus.TODO, dueDate: isoDaysFromNow(2) }),
      ]);

      const result = await service.getTasksNeedingDeadlineReminder(7);

      expect(result).toHaveLength(1);
      expect(result[0].assigneeUserId).toBe('user-1');
    });

    it('excludes completed and cancelled tasks', async () => {
      taskRepository.findAll.mockResolvedValue([
        buildTask({ id: 't1', status: TaskStatus.COMPLETED, dueDate: isoDaysFromNow(2) }),
        buildTask({ id: 't2', status: TaskStatus.CANCELLED, dueDate: isoDaysFromNow(2) }),
      ]);

      const result = await service.getTasksNeedingDeadlineReminder(7);
      expect(result).toHaveLength(0);
    });

    it('excludes a task already reminded for this exact dueDate', async () => {
      const dueDate = isoDaysFromNow(2);
      taskRepository.findAll.mockResolvedValue([
        buildTask({
          dueDate,
          lastDeadlineReminderSentFor: dueDate,
        }),
      ]);

      const result = await service.getTasksNeedingDeadlineReminder(7);
      expect(result).toHaveLength(0);
    });

    it('excludes a due date outside the daysBefore window', async () => {
      taskRepository.findAll.mockResolvedValue([
        buildTask({ dueDate: isoDaysFromNow(30) }),
      ]);

      const result = await service.getTasksNeedingDeadlineReminder(7);
      expect(result).toHaveLength(0);
    });
  });

  describe('markDeadlineReminderSent', () => {
    it('stamps lastDeadlineReminderSentFor with the task\'s current dueDate', async () => {
      taskRepository.findById.mockResolvedValue(
        buildTask({ id: 't1', dueDate: '2026-09-01' }),
      );

      await service.markDeadlineReminderSent('t1');

      expect(taskRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ lastDeadlineReminderSentFor: '2026-09-01' }),
      );
    });
  });

  describe('handleDailyDeadlineReminderCheck', () => {
    function isoDaysFromNow(days: number): string {
      const date = new Date();
      date.setDate(date.getDate() + days);
      return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
    }

    it('notifies each matching task\'s assignee directly and marks it sent, with no admin toggle involved', async () => {
      taskRepository.findAll.mockResolvedValue([
        buildTask({
          id: 't1',
          title: 'Ship the report',
          status: TaskStatus.TODO,
          dueDate: isoDaysFromNow(2),
        }),
      ]);
      taskRepository.findById.mockResolvedValue(
        buildTask({ id: 't1', dueDate: isoDaysFromNow(2) }),
      );

      await service.handleDailyDeadlineReminderCheck();

      expect(notificationsService.create).toHaveBeenCalledWith(
        expect.objectContaining({
          recipientUserId: 'user-1',
          linkTarget: 'tasks',
          linkEntityId: 't1',
        }),
      );
      expect(taskRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ lastDeadlineReminderSentFor: isoDaysFromNow(2) }),
      );
    });

    it('does nothing when no task is due soon', async () => {
      taskRepository.findAll.mockResolvedValue([
        buildTask({ dueDate: isoDaysFromNow(30) }),
      ]);

      await service.handleDailyDeadlineReminderCheck();

      expect(notificationsService.create).not.toHaveBeenCalled();
    });
  });
});
