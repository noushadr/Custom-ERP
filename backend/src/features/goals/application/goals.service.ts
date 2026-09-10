import {
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { resolveActorName } from '../../../core/utils/resolve-actor-name.util';
import {
  USER_REPOSITORY,
  type UserRepository,
} from '../../authentication/domain/repositories/user-repository.interface';
import { EmploymentStatus } from '../../employee/domain/enums/employment-status.enum';
import {
  EMPLOYEE_REPOSITORY,
  type EmployeeRepository,
} from '../../employee/domain/repositories/employee-repository.interface';
import { BulkAssignGoalDto } from './dto/bulk-assign-goal.dto';
import { CreateGoalDto } from './dto/create-goal.dto';
import { UpdateGoalDto } from './dto/update-goal.dto';
import { EmployeeGoal } from '../domain/entities/employee-goal.entity';
import {
  GOAL_REPOSITORY,
  type GoalRepository,
} from '../domain/repositories/goal-repository.interface';
import { GoalResponse } from './goal-response.interface';
import { toGoalResponse } from './goal.mapper';

@Injectable()
export class GoalsService {
  constructor(
    @Inject(GOAL_REPOSITORY)
    private readonly goalRepository: GoalRepository,
    @Inject(EMPLOYEE_REPOSITORY)
    private readonly employeeRepository: EmployeeRepository,
    @Inject(USER_REPOSITORY)
    private readonly userRepository: UserRepository,
  ) {}

  /** Every goal company-wide — gated by `goals.manage` at the controller. */
  async findAll(): Promise<GoalResponse[]> {
    const goals = await this.goalRepository.findAll();
    return goals.map(toGoalResponse);
  }

  /** This viewer's own goals, for their own dashboard — everyone can see
   * their own, no permission needed. */
  async findMine(actorUserId: string): Promise<GoalResponse[]> {
    const employee = await this.employeeRepository.findByUserId(actorUserId);
    if (!employee) return [];
    const goals = await this.goalRepository.findByEmployeeId(employee.id);
    return goals.map(toGoalResponse);
  }

  /** Goals belonging to this viewer's own direct reports — identity-scoped,
   * no `@Permissions` guard, same pattern as `getMyDirectReports`/
   * `getHistoryForMyTeam` elsewhere in this app. */
  async findForMyTeam(actorUserId: string): Promise<GoalResponse[]> {
    const manager = await this.employeeRepository.findByUserId(actorUserId);
    if (!manager) return [];
    const reports = await this.employeeRepository.findByReportingManagerId(
      manager.id,
    );
    const reportIds = new Set(reports.map((r) => r.id));
    const goals = await this.goalRepository.findAll();
    return goals
      .filter((goal) => reportIds.has(goal.employeeId))
      .map(toGoalResponse);
  }

  /** Admin/HR creating a goal for any employee — gated by `goals.manage` at
   * the controller. */
  async createForEmployee(
    dto: CreateGoalDto,
    actorUserId: string,
  ): Promise<GoalResponse> {
    const actorName = await resolveActorName(
      this.employeeRepository,
      this.userRepository,
      actorUserId,
    );
    return this.create(dto, actorUserId, actorName);
  }

  /** A Team Lead creating a goal for one of their own direct reports —
   * identity-scoped, no `@Permissions` guard, same shape as
   * `RequestsService.submitEmployeeOfMonthNomination`. */
  async createForMyDirectReport(
    actorUserId: string,
    dto: CreateGoalDto,
  ): Promise<GoalResponse> {
    const manager = await this.employeeRepository.findByUserId(actorUserId);
    if (!manager) throw new NotFoundException('Employee profile not found');

    const target = await this.employeeRepository.findById(dto.employeeId);
    if (!target || target.reportingManagerId !== manager.id) {
      throw new ForbiddenException(
        'You can only set goals for your own direct reports',
      );
    }

    return this.create(
      dto,
      actorUserId,
      `${manager.firstName} ${manager.lastName}`,
    );
  }

  /** Creates the same goal for every currently-active employee in one
   * department — Admin/HR only. */
  async bulkAssignToDepartment(
    dto: BulkAssignGoalDto,
    actorUserId: string,
  ): Promise<GoalResponse[]> {
    const actorName = await resolveActorName(
      this.employeeRepository,
      this.userRepository,
      actorUserId,
    );

    const employees = await this.employeeRepository.findAll();
    const targets = employees.filter(
      (employee) =>
        employee.departmentId === dto.departmentId &&
        employee.employmentStatus === EmploymentStatus.ACTIVE,
    );

    const goals = targets.map((employee) => {
      const goal = new EmployeeGoal();
      goal.employeeId = employee.id;
      goal.title = dto.title;
      goal.description = dto.description ?? null;
      goal.createdByUserId = actorUserId;
      goal.createdByName = actorName;
      return goal;
    });

    const saved = await this.goalRepository.saveMany(goals);
    // saveMany's returned rows don't carry the eager-loaded `employee`
    // relation the mapper needs — re-fetch each one the same way payroll's
    // generateRun does after its own bulk insert.
    const reloaded = await Promise.all(
      saved.map((goal) => this.goalRepository.findById(goal.id)),
    );
    return reloaded.filter((g): g is EmployeeGoal => g != null).map(toGoalResponse);
  }

  async update(
    goalId: string,
    dto: UpdateGoalDto,
    actorUserId: string,
    options: { requireOwnDirectReport: boolean },
  ): Promise<GoalResponse> {
    const goal = await this.loadForWrite(goalId, actorUserId, options);
    if (dto.title !== undefined) goal.title = dto.title;
    if (dto.description !== undefined) goal.description = dto.description;
    // Achievement % is Admin/HR only — a Team Lead's own edit route always
    // passes requireOwnDirectReport: true, so this silently no-ops for them
    // even if a request body includes it.
    if (
      dto.achievementPercentage !== undefined &&
      !options.requireOwnDirectReport
    ) {
      goal.achievementPercentage = dto.achievementPercentage;
    }
    const saved = await this.goalRepository.save(goal);
    return toGoalResponse(saved);
  }

  /** Soft-hides the goal instead of deleting it — same authorization split
   * as `update`: Admin/HR can archive any goal, a Team Lead only their own
   * direct reports'. */
  async archive(
    goalId: string,
    actorUserId: string,
    options: { requireOwnDirectReport: boolean },
  ): Promise<void> {
    const goal = await this.loadForWrite(goalId, actorUserId, options);
    goal.archived = true;
    await this.goalRepository.save(goal);
  }

  private create(
    dto: CreateGoalDto,
    actorUserId: string,
    actorName: string,
  ): Promise<GoalResponse> {
    const goal = new EmployeeGoal();
    goal.employeeId = dto.employeeId;
    goal.title = dto.title;
    goal.description = dto.description ?? null;
    goal.createdByUserId = actorUserId;
    goal.createdByName = actorName;

    return this.goalRepository
      .save(goal)
      .then((saved) => this.goalRepository.findById(saved.id))
      .then((reloaded) => toGoalResponse(reloaded!));
  }

  private async loadForWrite(
    goalId: string,
    actorUserId: string,
    options: { requireOwnDirectReport: boolean },
  ): Promise<EmployeeGoal> {
    const goal = await this.goalRepository.findById(goalId);
    if (!goal) throw new NotFoundException('Goal not found');

    if (options.requireOwnDirectReport) {
      const manager = await this.employeeRepository.findByUserId(actorUserId);
      if (!manager || goal.employee.reportingManagerId !== manager.id) {
        throw new ForbiddenException(
          'You can only manage goals for your own direct reports',
        );
      }
    }

    return goal;
  }
}
