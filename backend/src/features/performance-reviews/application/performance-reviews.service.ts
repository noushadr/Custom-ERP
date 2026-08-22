import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { definedFieldsOnly } from '../../../core/utils/defined-fields-only.util';
import { resolveActorName } from '../../../core/utils/resolve-actor-name.util';
import { RolesService } from '../../authentication/application/roles.service';
import {
  USER_REPOSITORY,
  type UserRepository,
} from '../../authentication/domain/repositories/user-repository.interface';
import { EmploymentStatus } from '../../employee/domain/enums/employment-status.enum';
import {
  EMPLOYEE_REPOSITORY,
  type EmployeeRepository,
} from '../../employee/domain/repositories/employee-repository.interface';
import { NotificationsService } from '../../notifications/application/notifications.service';
import { NotificationLinkTarget } from '../../notifications/domain/enums/notification-link-target.enum';
import { CreatePerformanceReviewCriterionDto } from './dto/create-performance-review-criterion.dto';
import { CreatePerformanceReviewDto } from './dto/create-performance-review.dto';
import { ReorderPerformanceReviewCriteriaDto } from './dto/reorder-performance-review-criteria.dto';
import { CompletePerformanceReviewDto } from './dto/complete-performance-review.dto';
import { UpdatePerformanceReviewCriterionDto } from './dto/update-performance-review-criterion.dto';
import { UpdatePerformanceReviewDto } from './dto/update-performance-review.dto';
import {
  PerformanceReviewResponseDto,
  PerformanceReviewSummaryDto,
} from './performance-review-response.interface';
import { toPerformanceReviewResponse } from './performance-review.mapper';
import { PerformanceReviewCriterion } from '../domain/entities/performance-review-criterion.entity';
import { PerformanceReviewResponse } from '../domain/entities/performance-review-response.entity';
import { PerformanceReview } from '../domain/entities/performance-review.entity';
import { PerformanceReviewStatus } from '../domain/enums/performance-review-status.enum';
import {
  PERFORMANCE_REVIEW_CRITERION_REPOSITORY,
  type PerformanceReviewCriterionRepository,
} from '../domain/repositories/performance-review-criterion-repository.interface';
import {
  PERFORMANCE_REVIEW_REPOSITORY,
  type PerformanceReviewRepository,
} from '../domain/repositories/performance-review-repository.interface';
import {
  PERFORMANCE_REVIEW_RESPONSE_REPOSITORY,
  type PerformanceReviewResponseRepository,
} from '../domain/repositories/performance-review-response-repository.interface';

const FOREIGN_KEY_VIOLATION = '23503';

export interface DueReviewItem {
  employeeId: string;
  employeeName: string;
  reviewYear: number;
  dueDate: string;
}

@Injectable()
export class PerformanceReviewsService {
  constructor(
    @Inject(PERFORMANCE_REVIEW_CRITERION_REPOSITORY)
    private readonly criterionRepository: PerformanceReviewCriterionRepository,
    @Inject(PERFORMANCE_REVIEW_REPOSITORY)
    private readonly reviewRepository: PerformanceReviewRepository,
    @Inject(PERFORMANCE_REVIEW_RESPONSE_REPOSITORY)
    private readonly responseRepository: PerformanceReviewResponseRepository,
    @Inject(EMPLOYEE_REPOSITORY)
    private readonly employeeRepository: EmployeeRepository,
    @Inject(USER_REPOSITORY)
    private readonly userRepository: UserRepository,
    private readonly notificationsService: NotificationsService,
    private readonly rolesService: RolesService,
  ) {}

  // ---- Criteria (template) management, configurable by performance.manage holders ----

  getCriteria(includeArchived = false): Promise<PerformanceReviewCriterion[]> {
    return this.criterionRepository.findAll(includeArchived);
  }

  async createCriterion(
    dto: CreatePerformanceReviewCriterionDto,
  ): Promise<PerformanceReviewCriterion> {
    const existing = await this.criterionRepository.findAll(true);

    const item = new PerformanceReviewCriterion();
    item.name = dto.name;
    item.responseType = dto.responseType;
    item.sortOrder = existing.length;
    item.isArchived = false;
    return this.criterionRepository.save(item);
  }

  async updateCriterion(
    id: string,
    dto: UpdatePerformanceReviewCriterionDto,
  ): Promise<PerformanceReviewCriterion> {
    const item = await this.criterionRepository.findById(id);
    if (!item) {
      throw new NotFoundException('Performance review criterion not found');
    }

    Object.assign(item, definedFieldsOnly(dto));
    return this.criterionRepository.save(item);
  }

  async reorderCriteria(
    dto: ReorderPerformanceReviewCriteriaDto,
  ): Promise<PerformanceReviewCriterion[]> {
    const items = await this.criterionRepository.findByIds(dto.orderedIds);
    const byId = new Map(items.map((item) => [item.id, item]));

    const reordered: PerformanceReviewCriterion[] = [];
    dto.orderedIds.forEach((id, index) => {
      const item = byId.get(id);
      if (!item) return;
      item.sortOrder = index;
      reordered.push(item);
    });
    return this.criterionRepository.saveMany(reordered);
  }

  async deleteCriterion(id: string): Promise<void> {
    const item = await this.criterionRepository.findById(id);
    if (!item) {
      throw new NotFoundException('Performance review criterion not found');
    }

    try {
      await this.criterionRepository.remove(item);
    } catch (error) {
      if (this.isForeignKeyViolation(error)) {
        throw new ConflictException(
          'Cannot delete a criterion that already has review responses ' +
            'recorded against it. Archive it instead.',
        );
      }
      throw error;
    }
  }

  // ---- Auto-creation: only the current due year, safe to call repeatedly ----

  async previewDueCheck(): Promise<DueReviewItem[]> {
    return this.computeDue();
  }

  async runDueCheck(): Promise<{
    created: number;
    reviews: PerformanceReviewResponseDto[];
  }> {
    const due = await this.computeDue();
    const reviews: PerformanceReview[] = [];
    for (const item of due) {
      const review = await this.createReviewInstance(
        item.employeeId,
        item.reviewYear,
        item.dueDate,
      );
      if (review) {
        reviews.push(review);
        await this.notifyReviewCreated(review);
      }
    }
    return {
      created: reviews.length,
      reviews: reviews.map(toPerformanceReviewResponse),
    };
  }

  /** Notifies the employee directly (their own review to self-assess) and
   * whoever needs to act on it — their reporting manager, or every
   * `performance.manage` holder if they don't have one set. */
  private async notifyReviewCreated(review: PerformanceReview): Promise<void> {
    const employee = await this.employeeRepository.findById(
      review.employeeId,
    );
    if (!employee) return;

    await this.notificationsService.create({
      recipientUserId: employee.userId,
      message: `Your ${review.reviewYear}-year performance review has been created.`,
      linkTarget: NotificationLinkTarget.PERFORMANCE_REVIEWS,
      linkEntityId: review.id,
    });

    const actionRecipients = employee.reportingManager
      ? [{ id: employee.reportingManager.userId }]
      : await this.rolesService.findUsersWithPermission(
          'performance.manage',
        );
    for (const recipient of actionRecipients) {
      await this.notificationsService.create({
        recipientUserId: recipient.id,
        message: `A ${review.reviewYear}-year performance review for ${employee.firstName} ${employee.lastName} is ready to rate.`,
        linkTarget: NotificationLinkTarget.PERFORMANCE_REVIEWS,
        linkEntityId: review.id,
      });
    }
  }

  /** Real automatic creation, once daily — `runDueCheck` is idempotent, so a
   * missed tick or a late deploy never duplicates anything. The
   * `POST /due-check/run` route calls the same method on demand, for
   * HR-triggered off-schedule runs and for testing without waiting on a
   * real clock tick. */
  @Cron(CronExpression.EVERY_DAY_AT_1AM)
  async handleDailyDueCheck(): Promise<void> {
    await this.runDueCheck();
  }

  /** Only ever considers each employee's *most recently elapsed* review
   * year (their current whole years of service) — never backfills earlier
   * years they never got a review for. A performance review is meant to be
   * one current, in-flight cycle per employee, not a stack of every
   * historical year created at once (e.g. a 10-year employee shouldn't
   * suddenly get 10 pending reviews the day this feature ships). */
  private async computeDue(): Promise<DueReviewItem[]> {
    const employees = await this.employeeRepository.findAll();
    const today = new Date();
    const due: DueReviewItem[] = [];

    for (const employee of employees) {
      if (
        employee.employmentStatus !== EmploymentStatus.ACTIVE &&
        employee.employmentStatus !== EmploymentStatus.ON_LEAVE
      ) {
        continue;
      }

      const joiningDate = new Date(employee.joiningDate);
      const reviewYear = this.wholeYearsOfService(joiningDate, today);
      if (reviewYear < 1) continue;

      const existing = await this.reviewRepository.findByEmployeeAndYear(
        employee.id,
        reviewYear,
      );
      if (existing) continue;

      const anniversary = new Date(joiningDate);
      anniversary.setFullYear(joiningDate.getFullYear() + reviewYear);
      due.push({
        employeeId: employee.id,
        employeeName: `${employee.firstName} ${employee.lastName}`,
        reviewYear,
        dueDate: anniversary.toISOString().slice(0, 10),
      });
    }
    return due;
  }

  /** Whole years elapsed between [joiningDate] and [today]. Inherits the
   * same Feb-29 rollover quirk as the existing anniversary-preview logic
   * (JS Date rolls a non-leap-year Feb 29 to Mar 1) — acceptable, matches
   * behavior already shipped elsewhere in this app. */
  private wholeYearsOfService(joiningDate: Date, today: Date): number {
    let years = today.getFullYear() - joiningDate.getFullYear();
    const anniversaryThisYear = new Date(joiningDate);
    anniversaryThisYear.setFullYear(joiningDate.getFullYear() + years);
    if (anniversaryThisYear > today) years -= 1;
    return years;
  }

  private async createReviewInstance(
    employeeId: string,
    reviewYear: number,
    dueDate: string,
  ): Promise<PerformanceReview | null> {
    const existing = await this.reviewRepository.findByEmployeeAndYear(
      employeeId,
      reviewYear,
    );
    if (existing) return null;

    const review = new PerformanceReview();
    review.employeeId = employeeId;
    review.reviewYear = reviewYear;
    review.dueDate = dueDate;
    review.status = PerformanceReviewStatus.PENDING;
    const saved = await this.reviewRepository.save(review);

    const criteria = await this.criterionRepository.findAll(false);
    if (criteria.length > 0) {
      const responses = criteria.map((criterion) => {
        const response = new PerformanceReviewResponse();
        response.performanceReviewId = saved.id;
        response.criterionId = criterion.id;
        response.criterionName = criterion.name;
        response.responseType = criterion.responseType;
        response.sortOrder = criterion.sortOrder;
        return response;
      });
      await this.responseRepository.saveMany(responses);
    }

    return this.reviewRepository.findById(saved.id);
  }

  async createManualReview(
    dto: CreatePerformanceReviewDto,
  ): Promise<PerformanceReviewResponseDto> {
    const existing = await this.reviewRepository.findByEmployeeAndYear(
      dto.employeeId,
      dto.reviewYear,
    );
    if (existing) {
      throw new ConflictException(
        `A review for year ${dto.reviewYear} already exists for this employee`,
      );
    }

    const dueDate = new Date().toISOString().slice(0, 10);
    const review = await this.createReviewInstance(
      dto.employeeId,
      dto.reviewYear,
      dueDate,
    );
    return toPerformanceReviewResponse(review!);
  }

  // ---- Reads ----

  async getMyReviews(
    actorUserId: string,
  ): Promise<PerformanceReviewResponseDto[]> {
    const employee = await this.employeeRepository.findByUserId(actorUserId);
    if (!employee) throw new NotFoundException('Employee profile not found');
    const reviews = await this.reviewRepository.findByEmployeeId(employee.id);
    return reviews.map(toPerformanceReviewResponse);
  }

  async getEmployeeReviews(
    employeeId: string,
  ): Promise<PerformanceReviewResponseDto[]> {
    const reviews = await this.reviewRepository.findByEmployeeId(employeeId);
    return reviews.map(toPerformanceReviewResponse);
  }

  /** Internal helper — returns the raw entity (with its `employee` and
   * `responses` relations) for other service methods to act on. Never
   * return this directly from a controller: map it with
   * toPerformanceReviewResponse first, since `employee` eager-loads
   * `Employee.user`, which eager-loads `User.passwordHash`. */
  private async getReviewById(id: string): Promise<PerformanceReview> {
    const review = await this.reviewRepository.findById(id);
    if (!review) throw new NotFoundException('Performance review not found');
    return review;
  }

  /** Access-controlled single-review fetch for the detail page: visible to
   * the review's own employee, their reporting manager, or a
   * `performance.manage` holder — never to an arbitrary authenticated user
   * who happens to know the id. */
  async getReviewByIdForActor(
    id: string,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<PerformanceReviewResponseDto> {
    const review = await this.getReviewById(id);
    if (actorHasOverride) return toPerformanceReviewResponse(review);

    const actor = await this.employeeRepository.findByUserId(actorUserId);
    const isSelf = actor != null && review.employeeId === actor.id;
    const isManager =
      actor != null && review.employee.reportingManagerId === actor.id;
    if (!isSelf && !isManager) {
      throw new ForbiddenException('You do not have access to this review');
    }
    return toPerformanceReviewResponse(review);
  }

  async getPendingManagerAction(
    actorUserId: string,
  ): Promise<PerformanceReviewResponseDto[]> {
    const manager = await this.employeeRepository.findByUserId(actorUserId);
    if (!manager) return [];

    const pending = await this.reviewRepository.findByStatus(
      PerformanceReviewStatus.PENDING,
    );
    return pending
      .filter((review) => review.employee.reportingManagerId === manager.id)
      .map(toPerformanceReviewResponse);
  }

  async getPendingHrFinalization(): Promise<PerformanceReviewResponseDto[]> {
    const reviews = await this.reviewRepository.findByStatus(
      PerformanceReviewStatus.COMPLETED,
    );
    return reviews.map(toPerformanceReviewResponse);
  }

  /** Every review company-wide still awaiting the reporting manager's (or
   * HR's) completion — not filtered to the caller's own direct reports, the
   * way `getPendingManagerAction` is. For a `performance.manage` holder's
   * dashboard/overview, where the point is visibility across the whole
   * company. */
  async getAllPendingReviews(): Promise<PerformanceReviewResponseDto[]> {
    const reviews = await this.reviewRepository.findByStatus(
      PerformanceReviewStatus.PENDING,
    );
    return reviews.map(toPerformanceReviewResponse);
  }

  /** Every review that has completed the full workflow — rated and signed
   * off by HR/Admin — for a company-wide review-history view. */
  async getFinalizedReviews(): Promise<PerformanceReviewResponseDto[]> {
    const reviews = await this.reviewRepository.findByStatus(
      PerformanceReviewStatus.FINALIZED,
    );
    return reviews.map(toPerformanceReviewResponse);
  }

  /** One summary per employee (their latest review, whatever its status) —
   * for a directory-style list showing "last review: done <date> / Pending"
   * without an N+1 fetch per employee. */
  async getLatestReviewSummaries(): Promise<PerformanceReviewSummaryDto[]> {
    const reviews = await this.reviewRepository.findLatestPerEmployee();
    return reviews.map((review) => ({
      employeeId: review.employeeId,
      reviewYear: review.reviewYear,
      dueDate: review.dueDate,
      status: review.status,
      completedAt: review.completedAt?.toISOString() ?? null,
      finalizedAt: review.finalizedAt?.toISOString() ?? null,
    }));
  }

  // ---- Workflow transitions ----

  /** [actorHasOverride] is true when the caller holds `performance.manage` —
   * resolved from the JWT at the controller, since a review's own reporting
   * manager (checked here by identity) isn't necessarily the only one
   * allowed to complete it: HR/Admin can step in too. */
  async completeReview(
    id: string,
    dto: CompletePerformanceReviewDto,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<PerformanceReviewResponseDto> {
    const review = await this.getReviewById(id);
    if (review.status !== PerformanceReviewStatus.PENDING) {
      throw new BadRequestException(
        'This review has already been completed',
      );
    }

    const actor = await this.employeeRepository.findByUserId(actorUserId);
    const isManager =
      actor != null && review.employee.reportingManagerId === actor.id;
    if (!isManager && !actorHasOverride) {
      throw new ForbiddenException(
        "You aren't the reporting manager for this review",
      );
    }

    const responsesById = new Map(
      review.responses.map((response) => [response.id, response]),
    );
    for (const entry of dto.responses) {
      const response = responsesById.get(entry.responseId);
      if (!response) continue;
      if (entry.ratingValue !== undefined) response.ratingValue = entry.ratingValue;
      if (entry.textValue !== undefined) response.textValue = entry.textValue;
    }
    await this.responseRepository.saveMany([...responsesById.values()]);

    review.status = PerformanceReviewStatus.COMPLETED;
    review.completedByUserId = actorUserId;
    review.completedByName = await resolveActorName(
      this.employeeRepository,
      this.userRepository,
      actorUserId,
    );
    review.completedAt = new Date();
    review.completedAsManager = isManager;
    await this.reviewRepository.save(review);
    return toPerformanceReviewResponse(await this.getReviewById(id));
  }

  async setSelfAssessment(
    id: string,
    comments: string,
    actorUserId: string,
  ): Promise<PerformanceReviewResponseDto> {
    const review = await this.getReviewById(id);
    if (review.status === PerformanceReviewStatus.FINALIZED) {
      throw new BadRequestException('This review has already been finalized');
    }

    const employee = await this.employeeRepository.findByUserId(actorUserId);
    if (!employee || review.employeeId !== employee.id) {
      throw new ForbiddenException(
        'You can only add comments to your own review',
      );
    }

    review.employeeComments = comments;
    await this.reviewRepository.save(review);
    return toPerformanceReviewResponse(await this.getReviewById(id));
  }

  async finalizeReview(
    id: string,
    actorUserId: string,
  ): Promise<PerformanceReviewResponseDto> {
    const review = await this.getReviewById(id);
    if (review.status !== PerformanceReviewStatus.COMPLETED) {
      throw new BadRequestException(
        'Only a completed review can be finalized',
      );
    }

    review.status = PerformanceReviewStatus.FINALIZED;
    review.finalizedByUserId = actorUserId;
    review.finalizedByName = await resolveActorName(
      this.employeeRepository,
      this.userRepository,
      actorUserId,
    );
    review.finalizedAt = new Date();
    await this.reviewRepository.save(review);
    return toPerformanceReviewResponse(await this.getReviewById(id));
  }

  async adminUpdateReview(
    id: string,
    dto: UpdatePerformanceReviewDto,
  ): Promise<PerformanceReviewResponseDto> {
    const review = await this.getReviewById(id);

    if (dto.employeeComments !== undefined) {
      review.employeeComments = dto.employeeComments;
    }

    if (dto.responses) {
      const responsesById = new Map(
        review.responses.map((response) => [response.id, response]),
      );
      for (const entry of dto.responses) {
        const response = responsesById.get(entry.responseId);
        if (!response) continue;
        if (entry.ratingValue !== undefined) response.ratingValue = entry.ratingValue;
        if (entry.textValue !== undefined) response.textValue = entry.textValue;
      }
      await this.responseRepository.saveMany([...responsesById.values()]);
    }

    await this.reviewRepository.save(review);
    return toPerformanceReviewResponse(await this.getReviewById(id));
  }

  private isForeignKeyViolation(error: unknown): boolean {
    const code =
      (error as { code?: string })?.code ??
      (error as { driverError?: { code?: string } })?.driverError?.code;
    return code === FOREIGN_KEY_VIOLATION;
  }
}
