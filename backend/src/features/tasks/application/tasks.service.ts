import {
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { definedFieldsOnly } from '../../../core/utils/defined-fields-only.util';
import { resolveActorName } from '../../../core/utils/resolve-actor-name.util';
import {
  USER_REPOSITORY,
  type UserRepository,
} from '../../authentication/domain/repositories/user-repository.interface';
import {
  DEPARTMENT_REPOSITORY,
  type DepartmentRepository,
} from '../../departments/domain/repositories/department-repository.interface';
import {
  EMPLOYEE_REPOSITORY,
  type EmployeeRepository,
} from '../../employee/domain/repositories/employee-repository.interface';
import { CreateTaskCommentDto } from './dto/create-task-comment.dto';
import { CreateTaskDto } from './dto/create-task.dto';
import { UpdateTaskStatusDto } from './dto/update-task-status.dto';
import { UpdateTaskDto } from './dto/update-task.dto';
import { Task } from '../domain/entities/task.entity';
import { TaskAuditLog } from '../domain/entities/task-audit-log.entity';
import { TaskComment } from '../domain/entities/task-comment.entity';
import { TaskPriority } from '../domain/enums/task-priority.enum';
import { TaskStatus } from '../domain/enums/task-status.enum';
import {
  TASK_AUDIT_LOG_REPOSITORY,
  type TaskAuditLogRepository,
} from '../domain/repositories/task-audit-log-repository.interface';
import {
  TASK_COMMENT_REPOSITORY,
  type TaskCommentRepository,
} from '../domain/repositories/task-comment-repository.interface';
import {
  TASK_REPOSITORY,
  type TaskRepository,
} from '../domain/repositories/task-repository.interface';
import {
  TaskAuditLogResponseDto,
  TaskCommentResponseDto,
  TaskResponseDto,
} from './task-response.interface';
import {
  toTaskAuditLogResponse,
  toTaskCommentResponse,
  toTaskResponse,
} from './task.mapper';

// Local-Y/M/D formatting, never .toISOString() — see AgencyReportingService
// for why: it silently rolls back a calendar day on a server running ahead
// of UTC.
function toIsoDate(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function addDays(date: Date, days: number): Date {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
}

@Injectable()
export class TasksService {
  constructor(
    @Inject(TASK_REPOSITORY)
    private readonly taskRepository: TaskRepository,
    @Inject(TASK_COMMENT_REPOSITORY)
    private readonly commentRepository: TaskCommentRepository,
    @Inject(TASK_AUDIT_LOG_REPOSITORY)
    private readonly auditLogRepository: TaskAuditLogRepository,
    @Inject(EMPLOYEE_REPOSITORY)
    private readonly employeeRepository: EmployeeRepository,
    @Inject(DEPARTMENT_REPOSITORY)
    private readonly departmentRepository: DepartmentRepository,
    @Inject(USER_REPOSITORY)
    private readonly userRepository: UserRepository,
  ) {}

  // ---- Lists ----

  /** "My Tasks" — assigned to the caller. */
  async getMyTasks(actorUserId: string): Promise<TaskResponseDto[]> {
    const actor = await this.employeeRepository.findByUserId(actorUserId);
    if (!actor) return [];
    const tasks = await this.taskRepository.findAll();
    return tasks
      .filter((task) => task.assigneeEmployeeId === actor.id)
      .map(toTaskResponse);
  }

  /** "Assigned Tasks" — created by the caller, for anyone else. */
  async getTasksAssignedByMe(actorUserId: string): Promise<TaskResponseDto[]> {
    const tasks = await this.taskRepository.findAll();
    return tasks
      .filter((task) => task.assignedByUserId === actorUserId)
      .map(toTaskResponse);
  }

  /** "Team Tasks" — every task company-wide for a `tasks.manage` holder,
   * or every task whose assignee is in a department the caller heads;
   * empty for anyone else. */
  async getTeamTasks(
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<TaskResponseDto[]> {
    const tasks = await this.taskRepository.findAll();
    if (actorHasOverride) return tasks.map(toTaskResponse);

    const actor = await this.employeeRepository.findByUserId(actorUserId);
    if (!actor) return [];
    const headedDepartmentIds = await this.getHeadedDepartmentIds(actor.id);
    if (headedDepartmentIds.size === 0) return [];

    return tasks
      .filter(
        (task) =>
          task.assignee.departmentId != null &&
          headedDepartmentIds.has(task.assignee.departmentId),
      )
      .map(toTaskResponse);
  }

  /** Clients & Projects' view of "which tasks belong to this project" —
   * controller-gated to clients.manage; unrelated to a linked task's own
   * visibility for its assignee. */
  async getTasksByProject(projectId: string): Promise<TaskResponseDto[]> {
    const tasks = await this.taskRepository.findByProjectId(projectId);
    return tasks.map(toTaskResponse);
  }

  // ---- Single task ----

  async getTaskForActor(
    id: string,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<TaskResponseDto> {
    const task = await this.getTaskOrThrow(id);
    if (!(await this.canView(task, actorUserId, actorHasOverride))) {
      throw new ForbiddenException('You do not have access to this task');
    }
    return toTaskResponse(task);
  }

  async getHistory(
    id: string,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<TaskAuditLogResponseDto[]> {
    const task = await this.getTaskOrThrow(id);
    if (!(await this.canView(task, actorUserId, actorHasOverride))) {
      throw new ForbiddenException('You do not have access to this task');
    }
    const logs = await this.auditLogRepository.findByTaskId(id);
    return logs.map(toTaskAuditLogResponse);
  }

  async getComments(
    id: string,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<TaskCommentResponseDto[]> {
    const task = await this.getTaskOrThrow(id);
    if (!(await this.canView(task, actorUserId, actorHasOverride))) {
      throw new ForbiddenException('You do not have access to this task');
    }
    const comments = await this.commentRepository.findByTaskId(id);
    return comments.map(toTaskCommentResponse);
  }

  async addComment(
    id: string,
    dto: CreateTaskCommentDto,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<TaskCommentResponseDto> {
    const task = await this.getTaskOrThrow(id);
    if (!(await this.canView(task, actorUserId, actorHasOverride))) {
      throw new ForbiddenException('You do not have access to this task');
    }

    const actorName = await resolveActorName(
      this.employeeRepository,
      this.userRepository,
      actorUserId,
    );
    const comment = new TaskComment();
    comment.taskId = id;
    comment.authorUserId = actorUserId;
    comment.authorName = actorName;
    comment.body = dto.body;
    const saved = await this.commentRepository.save(comment);
    return toTaskCommentResponse(saved);
  }

  // ---- Create / edit / status ----

  /** Create authority mirrors reassignment authority: a `tasks.manage`
   * holder can assign to anyone; otherwise the caller must head the
   * chosen assignee's department. */
  async createTask(
    dto: CreateTaskDto,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<TaskResponseDto> {
    if (
      !(await this.canAssignTo(
        dto.assigneeEmployeeId,
        actorUserId,
        actorHasOverride,
      ))
    ) {
      throw new ForbiddenException(
        "You aren't authorized to assign tasks to this employee",
      );
    }

    const { name: actorName, photoUrl: actorPhotoUrl } =
      await this.resolveActorNameAndPhoto(actorUserId);

    const task = new Task();
    task.title = dto.title;
    task.description = dto.description ?? null;
    task.assigneeEmployeeId = dto.assigneeEmployeeId;
    task.assignedByUserId = actorUserId;
    task.assignedByName = actorName;
    task.assignedByPhotoUrl = actorPhotoUrl;
    task.priority = dto.priority ?? TaskPriority.MEDIUM;
    task.dueDate = dto.dueDate;
    task.status = TaskStatus.TODO;
    task.projectId = dto.projectId ?? null;

    const saved = await this.taskRepository.save(task);
    const assigneeName = await this.employeeName(dto.assigneeEmployeeId);
    await this.addAuditLog(
      saved.id,
      actorUserId,
      'Created',
      null,
      `Assigned to ${assigneeName}`,
    );

    return toTaskResponse(await this.getTaskOrThrow(saved.id));
  }

  /** Edits core fields (title/description/priority/due date/assignee) — not
   * status, which has its own narrower/broader authority (see
   * `updateStatus`). Editing requires being the assigner, heading the
   * task's *current* assignee's department, or holding `tasks.manage`;
   * reassigning additionally requires the same authority over the *new*
   * assignee's department. */
  async updateTask(
    id: string,
    dto: UpdateTaskDto,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<TaskResponseDto> {
    const task = await this.getTaskOrThrow(id);
    if (!(await this.canEdit(task, actorUserId, actorHasOverride))) {
      throw new ForbiddenException(
        "You aren't authorized to edit this task",
      );
    }

    const changes = definedFieldsOnly(dto);

    if (
      changes.assigneeEmployeeId !== undefined &&
      changes.assigneeEmployeeId !== task.assigneeEmployeeId
    ) {
      if (
        !(await this.canAssignTo(
          changes.assigneeEmployeeId,
          actorUserId,
          actorHasOverride,
        ))
      ) {
        throw new ForbiddenException(
          "You aren't authorized to reassign this task to that employee",
        );
      }
      const [oldName, newName] = await Promise.all([
        this.employeeName(task.assigneeEmployeeId),
        this.employeeName(changes.assigneeEmployeeId),
      ]);
      await this.addAuditLog(task.id, actorUserId, 'Assignee', oldName, newName);
      const { name: actorName, photoUrl: actorPhotoUrl } =
        await this.resolveActorNameAndPhoto(actorUserId);
      task.assigneeEmployeeId = changes.assigneeEmployeeId;
      task.assignedByUserId = actorUserId;
      task.assignedByName = actorName;
      task.assignedByPhotoUrl = actorPhotoUrl;
    }

    if (changes.title !== undefined && changes.title !== task.title) {
      await this.addAuditLog(task.id, actorUserId, 'Title', task.title, changes.title);
      task.title = changes.title;
    }

    if (
      changes.description !== undefined &&
      changes.description !== task.description
    ) {
      await this.addAuditLog(
        task.id,
        actorUserId,
        'Description',
        task.description,
        changes.description,
      );
      task.description = changes.description;
    }

    if (changes.priority !== undefined && changes.priority !== task.priority) {
      await this.addAuditLog(
        task.id,
        actorUserId,
        'Priority',
        task.priority,
        changes.priority,
      );
      task.priority = changes.priority;
    }

    if (changes.dueDate !== undefined && changes.dueDate !== task.dueDate) {
      await this.addAuditLog(
        task.id,
        actorUserId,
        'Due Date',
        task.dueDate,
        changes.dueDate,
      );
      task.dueDate = changes.dueDate;
    }

    if (changes.projectId !== undefined) {
      task.projectId = changes.projectId;
    }

    await this.taskRepository.save(task);
    return toTaskResponse(await this.getTaskOrThrow(task.id));
  }

  /** Status is self-service: the assignee can update it themselves, in
   * addition to the assigner/department-head/override tiers who can edit
   * everything else. */
  async updateStatus(
    id: string,
    dto: UpdateTaskStatusDto,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<TaskResponseDto> {
    const task = await this.getTaskOrThrow(id);
    const actor = await this.employeeRepository.findByUserId(actorUserId);
    const isSelf = actor != null && task.assigneeEmployeeId === actor.id;
    if (
      !isSelf &&
      !(await this.canEdit(task, actorUserId, actorHasOverride))
    ) {
      throw new ForbiddenException(
        "You aren't authorized to update this task's status",
      );
    }

    if (dto.status !== task.status) {
      await this.addAuditLog(
        task.id,
        actorUserId,
        'Status',
        task.status,
        dto.status,
      );
      task.status = dto.status;
      task.completedAt = dto.status === TaskStatus.COMPLETED ? new Date() : null;
      await this.taskRepository.save(task);
    }

    return toTaskResponse(await this.getTaskOrThrow(task.id));
  }

  // ---- Authorization helpers ----

  /** Department ids where this employee is the head — the department-head
   * equivalent of "direct reports" for task assignment authority, matching
   * Leave's `getHeadedDepartmentIds`. */
  private async getHeadedDepartmentIds(
    employeeId: string,
  ): Promise<Set<string>> {
    const departments = await this.departmentRepository.findAll();
    return new Set(
      departments
        .filter((department) => department.headEmployeeId === employeeId)
        .map((department) => department.id),
    );
  }

  /** Visible to the assignee, the assigner, a department head whose headed
   * department contains the assignee, or a `tasks.manage` holder. */
  private async canView(
    task: Task,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<boolean> {
    if (actorHasOverride) return true;
    if (task.assignedByUserId === actorUserId) return true;

    const actor = await this.employeeRepository.findByUserId(actorUserId);
    if (!actor) return false;
    if (task.assigneeEmployeeId === actor.id) return true;
    if (!task.assignee.departmentId) return false;

    const headedDepartmentIds = await this.getHeadedDepartmentIds(actor.id);
    return headedDepartmentIds.has(task.assignee.departmentId);
  }

  /** Narrower than `canView` — excludes the assignee themself, since editing
   * the task's core fields is a creator/manager action, not a self action
   * (self gets its own status-only carve-out in `updateStatus`). */
  private async canEdit(
    task: Task,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<boolean> {
    if (actorHasOverride) return true;
    if (task.assignedByUserId === actorUserId) return true;
    if (!task.assignee.departmentId) return false;

    const actor = await this.employeeRepository.findByUserId(actorUserId);
    if (!actor) return false;
    const headedDepartmentIds = await this.getHeadedDepartmentIds(actor.id);
    return headedDepartmentIds.has(task.assignee.departmentId);
  }

  /** Whether the actor may create/reassign a task to [assigneeEmployeeId] —
   * true for a `tasks.manage` holder, or if the assignee's department is
   * one the actor heads. */
  private async canAssignTo(
    assigneeEmployeeId: string,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<boolean> {
    if (actorHasOverride) return true;

    const actor = await this.employeeRepository.findByUserId(actorUserId);
    if (!actor) return false;
    const assignee = await this.employeeRepository.findById(
      assigneeEmployeeId,
    );
    if (!assignee?.departmentId) return false;

    const headedDepartmentIds = await this.getHeadedDepartmentIds(actor.id);
    return headedDepartmentIds.has(assignee.departmentId);
  }

  /** Like `resolveActorName`, but also returns the actor's current photo
   * (null if they have no Employee profile or no photo) — used wherever the
   * assigner's name+photo are snapshotted together onto a Task. */
  private async resolveActorNameAndPhoto(
    actorUserId: string,
  ): Promise<{ name: string; photoUrl: string | null }> {
    const name = await resolveActorName(
      this.employeeRepository,
      this.userRepository,
      actorUserId,
    );
    const employee = await this.employeeRepository.findByUserId(actorUserId);
    return { name, photoUrl: employee?.profilePhotoUrl ?? null };
  }

  private async employeeName(employeeId: string): Promise<string> {
    const employee = await this.employeeRepository.findById(employeeId);
    return employee ? `${employee.firstName} ${employee.lastName}` : 'Unknown';
  }

  private async addAuditLog(
    taskId: string,
    actorUserId: string,
    fieldLabel: string,
    oldValue: string | null,
    newValue: string | null,
  ): Promise<void> {
    const actorName = await resolveActorName(
      this.employeeRepository,
      this.userRepository,
      actorUserId,
    );
    const log = new TaskAuditLog();
    log.taskId = taskId;
    log.actorUserId = actorUserId;
    log.actorName = actorName;
    log.fieldLabel = fieldLabel;
    log.oldValue = oldValue;
    log.newValue = newValue;
    await this.auditLogRepository.save(log);
  }

  private async getTaskOrThrow(id: string): Promise<Task> {
    const task = await this.taskRepository.findById(id);
    if (!task) throw new NotFoundException('Task not found');
    return task;
  }

  /** Open (not completed/cancelled) tasks whose `dueDate` falls within the
   * next `daysBefore` days and haven't already been notified for that
   * specific date — used by the Automations module's "Task Deadline
   * Reminder". Pair with `markDeadlineReminderSent` after notifying, so a
   * repeated check (daily cron or a manual "Run Now") never double-sends. */
  async getTasksNeedingDeadlineReminder(
    daysBefore: number,
  ): Promise<{ id: string; title: string; assigneeUserId: string }[]> {
    const tasks = await this.taskRepository.findAll();
    const today = new Date();
    const todayIso = toIsoDate(today);
    const windowEndIso = toIsoDate(addDays(today, daysBefore));

    return tasks
      .filter(
        (task) =>
          task.status !== TaskStatus.COMPLETED &&
          task.status !== TaskStatus.CANCELLED &&
          task.dueDate >= todayIso &&
          task.dueDate <= windowEndIso &&
          task.dueDate !== task.lastDeadlineReminderSentFor,
      )
      .map((task) => ({
        id: task.id,
        title: task.title,
        assigneeUserId: task.assignee.userId,
      }));
  }

  async markDeadlineReminderSent(taskId: string): Promise<void> {
    const task = await this.taskRepository.findById(taskId);
    if (!task) return;
    task.lastDeadlineReminderSentFor = task.dueDate;
    await this.taskRepository.save(task);
  }
}
