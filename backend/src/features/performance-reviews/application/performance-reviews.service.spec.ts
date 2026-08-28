import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Employee } from '../../employee/domain/entities/employee.entity';
import { EmploymentStatus } from '../../employee/domain/enums/employment-status.enum';
import type { EmployeeRepository } from '../../employee/domain/repositories/employee-repository.interface';
import type { RolesService } from '../../authentication/application/roles.service';
import type { UserRepository } from '../../authentication/domain/repositories/user-repository.interface';
import type { NotificationsService } from '../../notifications/application/notifications.service';
import { PerformanceReviewCriterion } from '../domain/entities/performance-review-criterion.entity';
import { PerformanceReviewResponse } from '../domain/entities/performance-review-response.entity';
import { PerformanceReview } from '../domain/entities/performance-review.entity';
import { CriterionResponseType } from '../domain/enums/criterion-response-type.enum';
import { PerformanceReviewStatus } from '../domain/enums/performance-review-status.enum';
import type { PerformanceReviewCriterionRepository } from '../domain/repositories/performance-review-criterion-repository.interface';
import type { PerformanceReviewRepository } from '../domain/repositories/performance-review-repository.interface';
import type { PerformanceReviewResponseRepository } from '../domain/repositories/performance-review-response-repository.interface';
import { PerformanceReviewsService } from './performance-reviews.service';

function buildCriterion(
  overrides: Partial<PerformanceReviewCriterion> = {},
): PerformanceReviewCriterion {
  return {
    id: 'criterion-1',
    name: 'Overall Performance',
    responseType: CriterionResponseType.RATING,
    sortOrder: 0,
    isArchived: false,
    ...overrides,
  } as PerformanceReviewCriterion;
}

function buildEmployee(overrides: Partial<Employee> = {}): Employee {
  return {
    id: 'employee-1',
    userId: 'user-1',
    firstName: 'Jane',
    lastName: 'Doe',
    reportingManagerId: 'manager-1',
    employmentStatus: EmploymentStatus.ACTIVE,
    joiningDate: '2020-01-01',
    ...overrides,
  } as Employee;
}

function buildResponse(
  overrides: Partial<PerformanceReviewResponse> = {},
): PerformanceReviewResponse {
  return {
    id: 'response-1',
    performanceReviewId: 'review-1',
    criterionId: 'criterion-1',
    criterionName: 'Overall Performance',
    responseType: CriterionResponseType.RATING,
    sortOrder: 0,
    ...overrides,
  } as PerformanceReviewResponse;
}

function buildReview(overrides: Partial<PerformanceReview> = {}): PerformanceReview {
  return {
    id: 'review-1',
    employeeId: 'employee-1',
    employee: buildEmployee(),
    reviewYear: 1,
    dueDate: '2021-01-01',
    status: PerformanceReviewStatus.PENDING,
    responses: [buildResponse()],
    createdAt: new Date('2025-01-01T00:00:00.000Z'),
    ...overrides,
  } as PerformanceReview;
}

describe('PerformanceReviewsService', () => {
  let service: PerformanceReviewsService;
  let criterionRepository: jest.Mocked<PerformanceReviewCriterionRepository>;
  let reviewRepository: jest.Mocked<PerformanceReviewRepository>;
  let responseRepository: jest.Mocked<PerformanceReviewResponseRepository>;
  let employeeRepository: jest.Mocked<EmployeeRepository>;
  let userRepository: jest.Mocked<UserRepository>;
  let notificationsService: jest.Mocked<NotificationsService>;
  let rolesService: jest.Mocked<RolesService>;

  beforeEach(() => {
    criterionRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      findByIds: jest.fn(),
      save: jest.fn((item) => Promise.resolve(item)),
      saveMany: jest.fn((items) => Promise.resolve(items)),
      remove: jest.fn(),
    };
    reviewRepository = {
      findByEmployeeId: jest.fn().mockResolvedValue([]),
      findByEmployeeAndYear: jest.fn().mockResolvedValue(null),
      findById: jest.fn(),
      findByStatus: jest.fn().mockResolvedValue([]),
      findLatestPerEmployee: jest.fn().mockResolvedValue([]),
      save: jest.fn((item) => Promise.resolve(item)),
    };
    responseRepository = {
      findByReviewId: jest.fn().mockResolvedValue([]),
      save: jest.fn((item) => Promise.resolve(item)),
      saveMany: jest.fn((items) => Promise.resolve(items)),
    };
    employeeRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      findByUserId: jest.fn(),
      findByReportingManagerId: jest.fn(),
      count: jest.fn(),
      save: jest.fn(),
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
    rolesService = {
      findUsersWithPermission: jest.fn().mockResolvedValue([]),
    } as unknown as jest.Mocked<RolesService>;

    service = new PerformanceReviewsService(
      criterionRepository,
      reviewRepository,
      responseRepository,
      employeeRepository,
      userRepository,
      notificationsService,
      rolesService,
    );
  });

  describe('createCriterion', () => {
    it('appends the new criterion to the end of the existing list', async () => {
      criterionRepository.findAll.mockResolvedValue([
        buildCriterion({ id: 'a' }),
        buildCriterion({ id: 'b' }),
      ]);

      const result = await service.createCriterion({
        name: 'Communication',
        responseType: CriterionResponseType.TEXT,
      });

      expect(result.sortOrder).toBe(2);
      expect(result.isArchived).toBe(false);
    });
  });

  describe('updateCriterion', () => {
    it('throws NotFoundException when missing', async () => {
      criterionRepository.findById.mockResolvedValue(null);

      await expect(
        service.updateCriterion('missing', { name: 'New name' }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('only touches fields explicitly provided', async () => {
      const item = buildCriterion({ name: 'Old name' });
      criterionRepository.findById.mockResolvedValue(item);

      const result = await service.updateCriterion(item.id, {
        isArchived: true,
      });

      expect(result.isArchived).toBe(true);
      expect(result.name).toBe('Old name');
    });
  });

  describe('reorderCriteria', () => {
    it("sets sortOrder to each id's position in the given order", async () => {
      const a = buildCriterion({ id: 'a', sortOrder: 0 });
      const b = buildCriterion({ id: 'b', sortOrder: 1 });
      criterionRepository.findByIds.mockResolvedValue([a, b]);

      const result = await service.reorderCriteria({ orderedIds: ['b', 'a'] });

      expect(result.find((i) => i.id === 'b')!.sortOrder).toBe(0);
      expect(result.find((i) => i.id === 'a')!.sortOrder).toBe(1);
    });
  });

  describe('deleteCriterion', () => {
    it('throws NotFoundException when missing', async () => {
      criterionRepository.findById.mockResolvedValue(null);

      await expect(service.deleteCriterion('missing')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('translates a foreign-key violation into a friendly ConflictException', async () => {
      const item = buildCriterion();
      criterionRepository.findById.mockResolvedValue(item);
      criterionRepository.remove.mockRejectedValue({ code: '23503' });

      await expect(service.deleteCriterion(item.id)).rejects.toBeInstanceOf(
        ConflictException,
      );
    });
  });

  describe('runDueCheck', () => {
    function joinedYearsAgo(years: number, extraDays = 2): string {
      const date = new Date();
      date.setFullYear(date.getFullYear() - years);
      date.setDate(date.getDate() - extraDays);
      return date.toISOString().slice(0, 10);
    }

    it('creates only the current (most recent) due year, never older ones', async () => {
      const employee = buildEmployee({ joiningDate: joinedYearsAgo(3) });
      employeeRepository.findAll.mockResolvedValue([employee]);
      criterionRepository.findAll.mockResolvedValue([buildCriterion()]);
      reviewRepository.findById.mockImplementation((id) =>
        Promise.resolve(buildReview({ id, reviewYear: 3 })),
      );

      const result = await service.runDueCheck();

      expect(result.created).toBe(1);
      expect(result.reviews[0].reviewYear).toBe(3);
      expect(reviewRepository.save).toHaveBeenCalledTimes(1);
      expect(responseRepository.saveMany).toHaveBeenCalledTimes(1);
    });

    it('is idempotent — skips when the current due year already exists', async () => {
      const employee = buildEmployee({ joiningDate: joinedYearsAgo(3) });
      employeeRepository.findAll.mockResolvedValue([employee]);
      criterionRepository.findAll.mockResolvedValue([buildCriterion()]);
      reviewRepository.findByEmployeeAndYear.mockImplementation((_id, year) =>
        Promise.resolve(year === 3 ? buildReview({ reviewYear: 3 }) : null),
      );

      const result = await service.runDueCheck();

      expect(result.created).toBe(0);
      expect(reviewRepository.save).not.toHaveBeenCalled();
    });

    it('skips employees who are not active or on leave', async () => {
      const employee = buildEmployee({
        joiningDate: joinedYearsAgo(3),
        employmentStatus: EmploymentStatus.RESIGNED,
      });
      employeeRepository.findAll.mockResolvedValue([employee]);

      const result = await service.runDueCheck();

      expect(result.created).toBe(0);
      expect(reviewRepository.save).not.toHaveBeenCalled();
    });

    it('skips employees with less than a full year of service', async () => {
      const employee = buildEmployee({ joiningDate: joinedYearsAgo(0) });
      employeeRepository.findAll.mockResolvedValue([employee]);

      const result = await service.runDueCheck();

      expect(result.created).toBe(0);
    });

    it('notifies the employee directly and their reporting manager when a review is created', async () => {
      const employee = buildEmployee({
        id: 'employee-1',
        userId: 'user-1',
        joiningDate: joinedYearsAgo(3),
        reportingManagerId: 'manager-1',
        reportingManager: buildEmployee({
          id: 'manager-1',
          userId: 'manager-user-1',
        }),
      });
      employeeRepository.findAll.mockResolvedValue([employee]);
      employeeRepository.findById.mockResolvedValue(employee);
      criterionRepository.findAll.mockResolvedValue([buildCriterion()]);
      reviewRepository.findById.mockImplementation((id) =>
        Promise.resolve(buildReview({ id, employeeId: 'employee-1', reviewYear: 3 })),
      );

      await service.runDueCheck();

      expect(notificationsService.create).toHaveBeenCalledWith(
        expect.objectContaining({ recipientUserId: 'user-1' }),
      );
      expect(notificationsService.create).toHaveBeenCalledWith(
        expect.objectContaining({ recipientUserId: 'manager-user-1' }),
      );
      expect(rolesService.findUsersWithPermission).not.toHaveBeenCalled();
    });

    it('falls back to notifying every performance.manage holder when the employee has no reporting manager', async () => {
      const employee = buildEmployee({
        id: 'employee-1',
        userId: 'user-1',
        joiningDate: joinedYearsAgo(3),
        reportingManagerId: undefined,
        reportingManager: undefined,
      });
      employeeRepository.findAll.mockResolvedValue([employee]);
      employeeRepository.findById.mockResolvedValue(employee);
      criterionRepository.findAll.mockResolvedValue([buildCriterion()]);
      reviewRepository.findById.mockImplementation((id) =>
        Promise.resolve(buildReview({ id, employeeId: 'employee-1', reviewYear: 3 })),
      );
      rolesService.findUsersWithPermission.mockResolvedValue([
        { id: 'hr-admin-1' } as never,
      ]);

      await service.runDueCheck();

      expect(rolesService.findUsersWithPermission).toHaveBeenCalledWith(
        'performance.manage',
      );
      expect(notificationsService.create).toHaveBeenCalledWith(
        expect.objectContaining({ recipientUserId: 'hr-admin-1' }),
      );
    });
  });

  describe('completeReview', () => {
    it('succeeds for the review employee\'s actual reporting manager', async () => {
      const review = buildReview();
      reviewRepository.findById.mockResolvedValue(review);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'manager-1', firstName: 'Manager', lastName: 'Person' }),
      );

      const result = await service.completeReview(
        review.id,
        { responses: [{ responseId: 'response-1', ratingValue: 4 }] },
        'manager-user-1',
        false,
      );

      expect(result.status).toBe(PerformanceReviewStatus.COMPLETED);
      expect(result.completedAsManager).toBe(true);
    });

    it('succeeds for a performance.manage holder who is not the manager', async () => {
      const review = buildReview();
      reviewRepository.findById.mockResolvedValue(review);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'hr-1', firstName: 'HR', lastName: 'Person' }),
      );

      const result = await service.completeReview(
        review.id,
        { responses: [{ responseId: 'response-1', ratingValue: 5 }] },
        'hr-user-1',
        true,
      );

      expect(result.status).toBe(PerformanceReviewStatus.COMPLETED);
      expect(result.completedAsManager).toBe(false);
    });

    it('is forbidden for someone who is neither the manager nor a permission holder', async () => {
      const review = buildReview();
      reviewRepository.findById.mockResolvedValue(review);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'someone-else' }),
      );

      await expect(
        service.completeReview(
          review.id,
          { responses: [{ responseId: 'response-1', ratingValue: 3 }] },
          'someone-user-1',
          false,
        ),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('rejects completing a review that is not pending', async () => {
      const review = buildReview({ status: PerformanceReviewStatus.COMPLETED });
      reviewRepository.findById.mockResolvedValue(review);

      await expect(
        service.completeReview(review.id, { responses: [] }, 'manager-user-1', true),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('setSelfAssessment', () => {
    it("lets the review's own employee add comments", async () => {
      const review = buildReview();
      reviewRepository.findById.mockResolvedValue(review);
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());

      const result = await service.setSelfAssessment(
        review.id,
        'Great year overall',
        'user-1',
      );

      expect(result.employeeComments).toBe('Great year overall');
    });

    it('is forbidden for someone other than the review\'s own employee', async () => {
      const review = buildReview();
      reviewRepository.findById.mockResolvedValue(review);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'someone-else' }),
      );

      await expect(
        service.setSelfAssessment(review.id, 'Not mine', 'other-user'),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });
  });

  describe('getReviewByIdForActor', () => {
    it("allows the review's own employee", async () => {
      const review = buildReview();
      reviewRepository.findById.mockResolvedValue(review);
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());

      await expect(
        service.getReviewByIdForActor(review.id, 'user-1', false),
      ).resolves.toMatchObject({ id: review.id });
    });

    it('allows the reporting manager', async () => {
      const review = buildReview();
      reviewRepository.findById.mockResolvedValue(review);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'manager-1' }),
      );

      await expect(
        service.getReviewByIdForActor(review.id, 'manager-user-1', false),
      ).resolves.toMatchObject({ id: review.id });
    });

    it('allows a performance.manage holder regardless of identity', async () => {
      const review = buildReview();
      reviewRepository.findById.mockResolvedValue(review);
      employeeRepository.findByUserId.mockResolvedValue(null);

      await expect(
        service.getReviewByIdForActor(review.id, 'hr-user-1', true),
      ).resolves.toMatchObject({ id: review.id });
    });

    it('is forbidden for an unrelated employee without the permission', async () => {
      const review = buildReview();
      reviewRepository.findById.mockResolvedValue(review);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'someone-else' }),
      );

      await expect(
        service.getReviewByIdForActor(review.id, 'other-user', false),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });
  });

  describe('getLatestReviewSummaries', () => {
    it("maps each employee's latest review to a lightweight summary", async () => {
      reviewRepository.findLatestPerEmployee.mockResolvedValue([
        buildReview({
          id: 'review-1',
          employeeId: 'employee-1',
          reviewYear: 2,
          status: PerformanceReviewStatus.PENDING,
        }),
        buildReview({
          id: 'review-2',
          employeeId: 'employee-2',
          reviewYear: 3,
          status: PerformanceReviewStatus.FINALIZED,
          finalizedAt: new Date('2026-02-01T00:00:00.000Z'),
        }),
      ]);

      const result = await service.getLatestReviewSummaries();

      expect(result).toEqual([
        {
          employeeId: 'employee-1',
          reviewYear: 2,
          dueDate: '2021-01-01',
          status: PerformanceReviewStatus.PENDING,
          completedAt: null,
          finalizedAt: null,
        },
        {
          employeeId: 'employee-2',
          reviewYear: 3,
          dueDate: '2021-01-01',
          status: PerformanceReviewStatus.FINALIZED,
          completedAt: null,
          finalizedAt: '2026-02-01T00:00:00.000Z',
        },
      ]);
    });
  });

  describe('getAllPendingReviews', () => {
    it('returns every pending review company-wide, unfiltered by manager', async () => {
      reviewRepository.findByStatus.mockResolvedValue([
        buildReview({ id: 'review-1', status: PerformanceReviewStatus.PENDING }),
        buildReview({ id: 'review-2', status: PerformanceReviewStatus.PENDING }),
      ]);

      const result = await service.getAllPendingReviews();

      expect(reviewRepository.findByStatus).toHaveBeenCalledWith(
        PerformanceReviewStatus.PENDING,
      );
      expect(result).toHaveLength(2);
    });
  });

  describe('getFinalizedReviews', () => {
    it('returns every finalized review company-wide', async () => {
      reviewRepository.findByStatus.mockResolvedValue([
        buildReview({ id: 'review-1', status: PerformanceReviewStatus.FINALIZED }),
      ]);

      const result = await service.getFinalizedReviews();

      expect(reviewRepository.findByStatus).toHaveBeenCalledWith(
        PerformanceReviewStatus.FINALIZED,
      );
      expect(result).toHaveLength(1);
    });
  });

  describe('finalizeReview', () => {
    it('requires the review to already be completed', async () => {
      const review = buildReview({ status: PerformanceReviewStatus.PENDING });
      reviewRepository.findById.mockResolvedValue(review);

      await expect(
        service.finalizeReview(review.id, 'hr-user-1'),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('finalizes a completed review', async () => {
      const review = buildReview({ status: PerformanceReviewStatus.COMPLETED });
      reviewRepository.findById.mockResolvedValue(review);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'hr-1', firstName: 'HR', lastName: 'Person' }),
      );

      const result = await service.finalizeReview(review.id, 'hr-user-1');

      expect(result.status).toBe(PerformanceReviewStatus.FINALIZED);
      expect(result.finalizedByName).toBe('HR Person');
    });
  });

  describe('unfinalizeReview', () => {
    it('requires the review to already be finalized', async () => {
      const review = buildReview({ status: PerformanceReviewStatus.COMPLETED });
      reviewRepository.findById.mockResolvedValue(review);

      await expect(
        service.unfinalizeReview(review.id),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('reverts a finalized review to completed and clears the finalized-by fields', async () => {
      const review = buildReview({
        status: PerformanceReviewStatus.FINALIZED,
        finalizedByUserId: 'hr-user-1',
        finalizedByName: 'HR Person',
        finalizedAt: new Date('2026-01-01T00:00:00.000Z'),
      });
      reviewRepository.findById.mockResolvedValue(review);

      const result = await service.unfinalizeReview(review.id);

      expect(result.status).toBe(PerformanceReviewStatus.COMPLETED);
      expect(result.finalizedByName).toBeNull();
      expect(result.finalizedAt).toBeNull();
      expect(reviewRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          finalizedByUserId: null,
          finalizedByName: null,
          finalizedAt: null,
        }),
      );
    });
  });
});
