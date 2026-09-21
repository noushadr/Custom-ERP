import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
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
import { NotificationsService } from '../../notifications/application/notifications.service';
import { NotificationLinkTarget } from '../../notifications/domain/enums/notification-link-target.enum';
import { AssignTeamMemberDto } from './dto/assign-team-member.dto';
import { CreateTaskCommentDto } from './dto/create-task-comment.dto';
import { CreateTaskDto } from './dto/create-task.dto';
import { UpdateTaskProgressDto } from './dto/update-task-progress.dto';
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

// Local-Y/M/D formatting, never .toISOString() — the latter silently rolls
// back a calendar day on a server running ahead of UTC.
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

const DEADLINE_REMINDER_DAYS_BEFORE = 7;

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
    private readonly notificationsService: NotificationsService,
  ) {}

  // ---- Lists ----

  /** "My Tasks" — assigned to the caller. */
  async getMyTasks(actorUserId: string): Promise<TaskResponseDto[]> {
    const actor = await this.employeeRepository.findByUserId(actorUserId);
    if (!actor) return [];
    const tasks = await this.taskRepository.findAll();
    return this.toResponsesWithCommentCounts(
      tasks.filter((task) => task.assigneeEmployeeId === actor.id),
    );
  }

  /** "Assigned Tasks" — created by the caller, for anyone else. */
  async getTasksAssignedByMe(actorUserId: string): Promise<TaskResponseDto[]> {
    const tasks = await this.taskRepository.findAll();
    return this.toResponsesWithCommentCounts(
      tasks.filter((task) => task.assignedByUserId === actorUserId),
    );
  }

  /** "Team Tasks" — every task company-wide for a `tasks.manage` holder,
   * or every task whose assignee is in a department the caller heads;
   * empty for anyone else. */
  async getTeamTasks(
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<TaskResponseDto[]> {
    const tasks = await this.taskRepository.findAll();
    if (actorHasOverride) return this.toResponsesWithCommentCounts(tasks);

    const actor = await this.employeeRepository.findByUserId(actorUserId);
    if (!actor) return [];
    const headedDepartmentIds = await this.getHeadedDepartmentIds(actor.id);
    if (headedDepartmentIds.size === 0) return [];

    return this.toResponsesWithCommentCounts(
      tasks.filter(
        (task) =>
          task.departmentId != null &&
          headedDepartmentIds.has(task.departmentId),
      ),
    );
  }

  /** Unclaimed tasks (assigned to a team, nobody picked yet) belonging to
   * the caller's own department — what they'd see to decide whether to
   * claim one. Empty for anyone with no department. */
  async getClaimableTasks(actorUserId: string): Promise<TaskResponseDto[]> {
    const actor = await this.employeeRepository.findByUserId(actorUserId);
    if (!actor?.departmentId) return [];
    const tasks = await this.taskRepository.findAll();
    return this.toResponsesWithCommentCounts(
      tasks.filter(
        (task) =>
          task.assigneeEmployeeId == null &&
          task.departmentId === actor.departmentId,
      ),
    );
  }

  /** Clients & Projects' view of "which tasks belong to this project" —
   * controller-gated to clients.manage; unrelated to a linked task's own
   * visibility for its assignee. */
  async getTasksByProject(projectId: string): Promise<TaskResponseDto[]> {
    const tasks = await this.taskRepository.findByProjectId(projectId);
    return this.toResponsesWithCommentCounts(tasks);
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
    return toTaskResponse(task, await this.commentCountFor(task.id));
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

  /** Two create paths in one method: assigning straight to a specific
   * employee keeps the exact same authority as before (override, or heading
   * that employee's department); assigning to a whole team instead needs no
   * authority check at all — any authenticated employee can hand a task to
   * a team, per explicit instruction, leaving the team itself to pick who
   * actually does it (see `assignTeamMember`/`claimTask`). Exactly one of
   * `assigneeEmployeeId`/`departmentId` must be given. */
  async createTask(
    dto: CreateTaskDto,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<TaskResponseDto> {
    const { name: actorName, photoUrl: actorPhotoUrl } =
      await this.resolveActorNameAndPhoto(actorUserId);

    const task = new Task();
    task.title = dto.title;
    task.description = dto.description ?? null;
    task.assignedByUserId = actorUserId;
    task.assignedByName = actorName;
    task.assignedByPhotoUrl = actorPhotoUrl;
    task.priority = dto.priority ?? TaskPriority.MEDIUM;
    task.dueDate = dto.dueDate;
    task.status = TaskStatus.TODO;
    task.projectId = dto.projectId ?? null;
    task.progressRemarks = null;

    let auditNote: string;
    if (dto.assigneeEmployeeId) {
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
      const assignee = await this.employeeRepository.findById(
        dto.assigneeEmployeeId,
      );
      task.assigneeEmployeeId = dto.assigneeEmployeeId;
      task.departmentId = assignee?.departmentId ?? null;
      auditNote = `Assigned to ${await this.employeeName(dto.assigneeEmployeeId)}`;
    } else if (dto.departmentId) {
      const department = await this.departmentRepository.findById(
        dto.departmentId,
      );
      if (!department) throw new NotFoundException('Department not found');
      task.assigneeEmployeeId = null;
      task.departmentId = dto.departmentId;
      auditNote = `Assigned to team: ${department.name}`;
    } else {
      throw new BadRequestException(
        'Choose an employee or a team to assign this task to',
      );
    }

    const saved = await this.taskRepository.save(task);
    await this.addAuditLog(saved.id, actorUserId, 'Created', null, auditNote);

    return this.taskResponseFor(saved.id);
  }

  /** A team's head (department head) picking a specific member for a
   * currently-unclaimed team task — same authority as directly assigning to
   * that employee anywhere else (`canAssignTo`), plus confirming the
   * employee actually belongs to *this task's* department (an actor who
   * heads more than one department could otherwise assign in a mismatched
   * team). */
  async assignTeamMember(
    id: string,
    dto: AssignTeamMemberDto,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<TaskResponseDto> {
    const task = await this.getTaskOrThrow(id);
    if (task.assigneeEmployeeId != null) {
      throw new ForbiddenException('This task is already assigned to someone');
    }
    if (
      !(await this.canAssignTo(dto.employeeId, actorUserId, actorHasOverride))
    ) {
      throw new ForbiddenException(
        "You aren't authorized to assign this task to that employee",
      );
    }
    const assignee = await this.employeeRepository.findById(dto.employeeId);
    if (!assignee || assignee.departmentId !== task.departmentId) {
      throw new ForbiddenException(
        "That employee isn't a member of this task's team",
      );
    }

    task.assigneeEmployeeId = dto.employeeId;
    await this.taskRepository.save(task);
    const assigneeName = await this.employeeName(dto.employeeId);
    await this.addAuditLog(task.id, actorUserId, 'Assignee', null, assigneeName);
    await this.notifyAssigner(
      task,
      actorUserId,
      `${assigneeName} was assigned to task "${task.title}"`,
    );

    return this.taskResponseFor(task.id);
  }

  /** Any member of the task's own team can claim an unclaimed team task for
   * themselves — no approval step, they become the assignee immediately. */
  async claimTask(id: string, actorUserId: string): Promise<TaskResponseDto> {
    const task = await this.getTaskOrThrow(id);
    if (task.assigneeEmployeeId != null) {
      throw new ForbiddenException('This task has already been claimed');
    }
    const actor = await this.employeeRepository.findByUserId(actorUserId);
    if (!actor || actor.departmentId !== task.departmentId) {
      throw new ForbiddenException("You aren't a member of this task's team");
    }

    task.assigneeEmployeeId = actor.id;
    await this.taskRepository.save(task);
    const actorName = `${actor.firstName} ${actor.lastName}`;
    await this.addAuditLog(task.id, actorUserId, 'Assignee', null, actorName);
    await this.notifyAssigner(
      task,
      actorUserId,
      `${actorName} accepted task "${task.title}"`,
    );

    return this.taskResponseFor(task.id);
  }

  /** Edits core fields (title/description/priority/due date/assignee) — not
   * status, which has its own narrower/broader authority (see
   * `updateStatus`). Editing requires being the assigner, heading the
   * task's *current* assignee's department (a Team Lead's authority), or
   * holding `tasks.manage` (Super Admin/HR-Manager) — i.e. exactly the same
   * three-tier authority `updateStatus`'s non-self branch uses; reassigning
   * additionally requires that same authority over the *new* assignee's
   * department. */
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
      const [oldName, newName, newAssignee] = await Promise.all([
        this.employeeName(task.assigneeEmployeeId),
        this.employeeName(changes.assigneeEmployeeId),
        this.employeeRepository.findById(changes.assigneeEmployeeId),
      ]);
      await this.addAuditLog(task.id, actorUserId, 'Assignee', oldName, newName);
      const { name: actorName, photoUrl: actorPhotoUrl } =
        await this.resolveActorNameAndPhoto(actorUserId);
      task.assigneeEmployeeId = changes.assigneeEmployeeId;
      task.departmentId = newAssignee?.departmentId ?? task.departmentId;
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
    return this.taskResponseFor(task.id);
  }

  /** Status/progress remarks are self-service: the assignee can update
   * either themselves, in addition to the assigner/department-head/override
   * tiers who can edit everything else. Due date is NOT self-service — only
   * the assigner, a department head over the task, or a `tasks.manage`
   * holder (Super Admin/HR) may move the deadline, same authority as
   * `updateTask`'s core-field edits. Only the assignee's own edit notifies
   * the assigner — a privileged editor changing these same fields doesn't
   * need to notify themselves. */
  async updateProgress(
    id: string,
    dto: UpdateTaskProgressDto,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<TaskResponseDto> {
    const task = await this.getTaskOrThrow(id);
    const actor = await this.employeeRepository.findByUserId(actorUserId);
    const isSelf = actor != null && task.assigneeEmployeeId === actor.id;
    const hasElevatedAccess =
      !isSelf || dto.dueDate !== undefined
        ? await this.canEdit(task, actorUserId, actorHasOverride)
        : false;
    if (!isSelf && !hasElevatedAccess) {
      throw new ForbiddenException(
        "You aren't authorized to update this task",
      );
    }
    if (dto.dueDate !== undefined && isSelf && !hasElevatedAccess) {
      throw new ForbiddenException(
        "Only the task's assigner, a department head, or an admin/HR can change the due date",
      );
    }

    const changeSummaries: string[] = [];

    if (dto.status !== undefined && dto.status !== task.status) {
      await this.addAuditLog(task.id, actorUserId, 'Status', task.status, dto.status);
      changeSummaries.push(`status → ${dto.status}`);
      task.status = dto.status;
      task.completedAt = dto.status === TaskStatus.COMPLETED ? new Date() : null;
    }

    if (dto.dueDate !== undefined && dto.dueDate !== task.dueDate) {
      await this.addAuditLog(
        task.id,
        actorUserId,
        'Due Date',
        task.dueDate,
        dto.dueDate,
      );
      changeSummaries.push(`due date → ${dto.dueDate}`);
      task.dueDate = dto.dueDate;
    }

    if (
      dto.progressRemarks !== undefined &&
      dto.progressRemarks !== task.progressRemarks
    ) {
      await this.addAuditLog(
        task.id,
        actorUserId,
        'Progress Remarks',
        task.progressRemarks,
        dto.progressRemarks,
      );
      changeSummaries.push('progress remarks updated');
      task.progressRemarks = dto.progressRemarks;
    }

    if (changeSummaries.length > 0) {
      await this.taskRepository.save(task);
      if (isSelf) {
        await this.notifyAssigner(
          task,
          actorUserId,
          `${actor!.firstName} ${actor!.lastName} updated task "${task.title}": ${changeSummaries.join(', ')}`,
        );
      }
    }

    return this.taskResponseFor(task.id);
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

  /** Visible to the assignee, the assigner, any member of the task's own
   * team while it's still unclaimed (so they can see it's available), a
   * department head whose headed department contains the task, or a
   * `tasks.manage` holder. */
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
    if (
      task.assigneeEmployeeId == null &&
      task.departmentId != null &&
      actor.departmentId === task.departmentId
    ) {
      return true;
    }
    if (!task.departmentId) return false;

    const headedDepartmentIds = await this.getHeadedDepartmentIds(actor.id);
    return headedDepartmentIds.has(task.departmentId);
  }

  /** Narrower than `canView` — excludes the assignee themself, since editing
   * the task's core fields is a creator/manager action, not a self action
   * (self gets its own broader carve-out in `updateProgress`). Shared by
   * `updateTask` and `updateProgress`'s non-self branch — both editing and
   * overriding someone else's progress are the same assigner/department-
   * head/tasks.manage tier, admin+TL+HR by role. */
  private async canEdit(
    task: Task,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<boolean> {
    if (actorHasOverride) return true;
    if (task.assignedByUserId === actorUserId) return true;
    if (!task.departmentId) return false;

    const actor = await this.employeeRepository.findByUserId(actorUserId);
    if (!actor) return false;
    const headedDepartmentIds = await this.getHeadedDepartmentIds(actor.id);
    return headedDepartmentIds.has(task.departmentId);
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

  private async employeeName(employeeId: string | null): Promise<string> {
    if (!employeeId) return 'Unassigned';
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

  /** Re-fetches a single task by id and attaches its comment count — the
   * single-task counterpart to `toResponsesWithCommentCounts`, used after a
   * create/claim/assign/edit that already has the id in hand. */
  private async taskResponseFor(id: string): Promise<TaskResponseDto> {
    const task = await this.getTaskOrThrow(id);
    return toTaskResponse(task, await this.commentCountFor(id));
  }

  private async commentCountFor(taskId: string): Promise<number> {
    return (await this.commentRepository.countByTaskIds([taskId])).get(
      taskId,
    ) ?? 0;
  }

  /** Batched comment-count lookup (one query, not N) for a list of tasks —
   * shared by every list endpoint (My Tasks, Assigned Tasks, Team Tasks,
   * Claimable, by-project). */
  private async toResponsesWithCommentCounts(
    tasks: Task[],
  ): Promise<TaskResponseDto[]> {
    const counts = await this.commentRepository.countByTaskIds(
      tasks.map((task) => task.id),
    );
    return tasks.map((task) => toTaskResponse(task, counts.get(task.id) ?? 0));
  }

  /** Notifies whoever assigned/created the task — used when the assignee
   * claims a team task, gets picked by their team's head, or updates their
   * own progress. Never notifies the assigner about their own action (a
   * task the assigner also happens to be the assignee for). */
  private async notifyAssigner(
    task: Task,
    actingUserId: string,
    message: string,
  ): Promise<void> {
    if (task.assignedByUserId === actingUserId) return;
    await this.notificationsService.create({
      recipientUserId: task.assignedByUserId,
      message,
      linkTarget: NotificationLinkTarget.TASKS,
      linkEntityId: task.id,
    });
  }

  /** Unconditional daily check — every open task's own assignee is always
   * notified 7 days before its due date, with no admin on/off toggle.
   * Idempotent via `lastDeadlineReminderSentFor`, so a missed tick or a late
   * deploy never duplicates a reminder. */
  @Cron(CronExpression.EVERY_DAY_AT_2AM)
  async handleDailyDeadlineReminderCheck(): Promise<void> {
    const matches = await this.getTasksNeedingDeadlineReminder(
      DEADLINE_REMINDER_DAYS_BEFORE,
    );
    for (const task of matches) {
      await this.notificationsService.create({
        recipientUserId: task.assigneeUserId,
        message: `Task "${task.title}" is due soon.`,
        linkTarget: NotificationLinkTarget.TASKS,
        linkEntityId: task.id,
      });
      await this.markDeadlineReminderSent(task.id);
    }
  }

  /** Open (not completed/cancelled) tasks whose `dueDate` falls within the
   * next `daysBefore` days and haven't already been notified for that
   * specific date. Pair with `markDeadlineReminderSent` after notifying, so
   * a repeated check never double-sends. */
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
          task.assignee != null &&
          task.status !== TaskStatus.COMPLETED &&
          task.status !== TaskStatus.CANCELLED &&
          task.dueDate >= todayIso &&
          task.dueDate <= windowEndIso &&
          task.dueDate !== task.lastDeadlineReminderSentFor,
      )
      .map((task) => ({
        id: task.id,
        title: task.title,
        assigneeUserId: task.assignee!.userId,
      }));
  }

  async markDeadlineReminderSent(taskId: string): Promise<void> {
    const task = await this.taskRepository.findById(taskId);
    if (!task) return;
    task.lastDeadlineReminderSentFor = task.dueDate;
    await this.taskRepository.save(task);
  }
}
