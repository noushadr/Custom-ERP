import { Inject, Injectable, NotFoundException, OnModuleInit } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { resolveActorName } from '../../../core/utils/resolve-actor-name.util';
import {
  USER_REPOSITORY,
  type UserRepository,
} from '../../authentication/domain/repositories/user-repository.interface';
import { RolesService } from '../../authentication/application/roles.service';
import { ClientsService } from '../../clients/application/clients.service';
import {
  EMPLOYEE_REPOSITORY,
  type EmployeeRepository,
} from '../../employee/domain/repositories/employee-repository.interface';
import { LeaveService } from '../../leave/application/leave.service';
import { NotificationLinkTarget } from '../../notifications/domain/enums/notification-link-target.enum';
import { NotificationsService } from '../../notifications/application/notifications.service';
import { TasksService } from '../../tasks/application/tasks.service';
import { UpdateAutomationDto } from './dto/update-automation.dto';
import { Automation } from '../domain/entities/automation.entity';
import { AutomationExecutionHistory } from '../domain/entities/automation-execution-history.entity';
import { AutomationRunStatus } from '../domain/enums/automation-run-status.enum';
import { AutomationRunTrigger } from '../domain/enums/automation-run-trigger.enum';
import { AutomationType } from '../domain/enums/automation-type.enum';
import {
  AUTOMATION_EXECUTION_HISTORY_REPOSITORY,
  type AutomationExecutionHistoryRepository,
} from '../domain/repositories/automation-execution-history-repository.interface';
import {
  AUTOMATION_REPOSITORY,
  type AutomationRepository,
} from '../domain/repositories/automation-repository.interface';
import {
  AutomationExecutionHistoryResponseDto,
  AutomationResponseDto,
} from './automations-response.interface';
import {
  toAutomationExecutionHistoryResponse,
  toAutomationResponse,
} from './automations.mapper';

interface RunResult {
  itemsProcessed: number;
  notificationsCreated: number;
}

const DEFAULT_DAYS_BEFORE = 7;

@Injectable()
export class AutomationsService implements OnModuleInit {
  constructor(
    @Inject(AUTOMATION_REPOSITORY)
    private readonly automationRepository: AutomationRepository,
    @Inject(AUTOMATION_EXECUTION_HISTORY_REPOSITORY)
    private readonly historyRepository: AutomationExecutionHistoryRepository,
    @Inject(EMPLOYEE_REPOSITORY)
    private readonly employeeRepository: EmployeeRepository,
    @Inject(USER_REPOSITORY)
    private readonly userRepository: UserRepository,
    private readonly clientsService: ClientsService,
    private readonly tasksService: TasksService,
    private readonly leaveService: LeaveService,
    private readonly notificationsService: NotificationsService,
    private readonly rolesService: RolesService,
  ) {}

  /** Ensures exactly one row per AutomationType exists — this is a fixed
   * catalog, never admin-created/deleted, so the rows are seeded here
   * rather than via a migration (keeps AutomationType as the single source
   * of truth for which rows should exist). */
  async onModuleInit(): Promise<void> {
    const existing = await this.automationRepository.findAll();
    const existingTypes = new Set(existing.map((a) => a.type));

    for (const type of Object.values(AutomationType)) {
      if (existingTypes.has(type)) continue;
      const automation = new Automation();
      automation.type = type;
      automation.isActive = false;
      automation.daysBefore =
        type === AutomationType.ANNUAL_LEAVE_RESET ? null : DEFAULT_DAYS_BEFORE;
      await this.automationRepository.save(automation);
    }
  }

  async getAutomations(): Promise<AutomationResponseDto[]> {
    const automations = await this.automationRepository.findAll();
    return automations.map(toAutomationResponse);
  }

  async updateAutomation(
    type: AutomationType,
    dto: UpdateAutomationDto,
    actorUserId: string,
  ): Promise<AutomationResponseDto> {
    const automation = await this.automationRepository.findByType(type);
    if (!automation) throw new NotFoundException('Automation not found');

    if (dto.isActive !== undefined) automation.isActive = dto.isActive;
    if (dto.daysBefore !== undefined) automation.daysBefore = dto.daysBefore;
    automation.updatedByName = await resolveActorName(
      this.employeeRepository,
      this.userRepository,
      actorUserId,
    );

    const saved = await this.automationRepository.save(automation);
    return toAutomationResponse(saved);
  }

  async getExecutionHistory(
    type?: AutomationType,
  ): Promise<AutomationExecutionHistoryResponseDto[]> {
    const entries = await this.historyRepository.findAll(type);
    return entries.map(toAutomationExecutionHistoryResponse);
  }

  /** Real automatic run, once daily — each handler is idempotent (see
   * `Project.lastRenewalReminderSentFor`/`Task.lastDeadlineReminderSentFor`
   * and the leave reset's own `getResetStatus` check), so a missed tick or
   * a late deploy never duplicates a reminder. Staggered an hour after the
   * performance-review due-check to avoid both crons landing at once. */
  @Cron(CronExpression.EVERY_DAY_AT_2AM)
  async handleDailyAutomationsCheck(): Promise<void> {
    const automations = await this.automationRepository.findAll();
    for (const automation of automations) {
      if (automation.isActive) {
        await this.runAutomation(automation.type, AutomationRunTrigger.CRON);
      }
    }
  }

  /** Runs one automation's check regardless of its `isActive` flag — used
   * by the cron (which only calls this for active automations) and by the
   * `POST /automations/:type/run` route (an admin explicitly testing/
   * running it now, same "manual trigger" convention as the leave module's
   * `/leave/reset`). Always writes exactly one execution-history row. */
  async runAutomation(
    type: AutomationType,
    triggeredBy: AutomationRunTrigger,
  ): Promise<AutomationExecutionHistoryResponseDto> {
    const automation = await this.automationRepository.findByType(type);
    if (!automation) throw new NotFoundException('Automation not found');

    let result: RunResult = { itemsProcessed: 0, notificationsCreated: 0 };
    let status = AutomationRunStatus.SUCCESS;
    let errorMessage: string | null = null;

    try {
      switch (type) {
        case AutomationType.PROJECT_RENEWAL_REMINDER:
          result = await this.runProjectRenewalReminder(
            automation.daysBefore ?? DEFAULT_DAYS_BEFORE,
          );
          break;
        case AutomationType.TASK_DEADLINE_REMINDER:
          result = await this.runTaskDeadlineReminder(
            automation.daysBefore ?? DEFAULT_DAYS_BEFORE,
          );
          break;
        case AutomationType.ANNUAL_LEAVE_RESET:
          result = await this.runAnnualLeaveReset();
          break;
      }
    } catch (error) {
      status = AutomationRunStatus.ERROR;
      errorMessage = error instanceof Error ? error.message : 'Unknown error';
    }

    const entry = new AutomationExecutionHistory();
    entry.type = type;
    entry.triggeredBy = triggeredBy;
    entry.status = status;
    entry.itemsProcessed = result.itemsProcessed;
    entry.notificationsCreated = result.notificationsCreated;
    entry.errorMessage = errorMessage;
    const saved = await this.historyRepository.save(entry);
    return toAutomationExecutionHistoryResponse(saved);
  }

  // ---------------------------------------------------------------------
  // Per-automation handlers
  // ---------------------------------------------------------------------

  /** Notifies every `clients.manage` holder (the same audience gated onto
   * Clients & Projects itself) about retainers renewing soon. */
  private async runProjectRenewalReminder(
    daysBefore: number,
  ): Promise<RunResult> {
    const matches =
      await this.clientsService.getProjectsNeedingRenewalReminder(daysBefore);
    if (matches.length === 0) {
      return { itemsProcessed: 0, notificationsCreated: 0 };
    }

    const recipients =
      await this.rolesService.findUsersWithPermission('clients.manage');
    let notificationsCreated = 0;
    for (const project of matches) {
      for (const recipient of recipients) {
        await this.notificationsService.create({
          recipientUserId: recipient.id,
          message: `${project.clientName}'s "${project.name}" renews on ${project.renewalDate}.`,
          linkTarget: NotificationLinkTarget.CLIENTS_PROJECTS,
          linkEntityId: project.id,
        });
        notificationsCreated++;
      }
      await this.clientsService.markRenewalReminderSent(project.id);
    }
    return { itemsProcessed: matches.length, notificationsCreated };
  }

  /** Notifies each task's own assignee directly — unlike the other two
   * automations, this isn't scoped to Admin Business Management's
   * audience, since a task deadline is the assignee's own concern. */
  private async runTaskDeadlineReminder(daysBefore: number): Promise<RunResult> {
    const matches =
      await this.tasksService.getTasksNeedingDeadlineReminder(daysBefore);
    if (matches.length === 0) {
      return { itemsProcessed: 0, notificationsCreated: 0 };
    }

    let notificationsCreated = 0;
    for (const task of matches) {
      await this.notificationsService.create({
        recipientUserId: task.assigneeUserId,
        message: `Task "${task.title}" is due soon.`,
        linkTarget: NotificationLinkTarget.TASKS,
        linkEntityId: task.id,
      });
      notificationsCreated++;
      await this.tasksService.markDeadlineReminderSent(task.id);
    }
    return { itemsProcessed: matches.length, notificationsCreated };
  }

  /** Runs the existing manual annual-reset logic automatically instead of
   * requiring HR/Admin to click the button — `getResetStatus` already
   * makes this idempotent (a no-op once the year is initialized). */
  private async runAnnualLeaveReset(): Promise<RunResult> {
    const status = await this.leaveService.getResetStatus();
    if (status.isInitialized) {
      return { itemsProcessed: 0, notificationsCreated: 0 };
    }

    const result = await this.leaveService.runAnnualReset();
    const recipients =
      await this.rolesService.findUsersWithPermission('leave.manage');
    for (const recipient of recipients) {
      await this.notificationsService.create({
        recipientUserId: recipient.id,
        message: `Annual leave balances for ${result.year} were reset automatically (${result.balancesCreated} balance(s) created).`,
        linkTarget: NotificationLinkTarget.LEAVE,
      });
    }
    return {
      itemsProcessed: result.balancesCreated,
      notificationsCreated: recipients.length,
    };
  }
}
