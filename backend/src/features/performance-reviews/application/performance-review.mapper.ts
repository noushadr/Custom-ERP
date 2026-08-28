import { PerformanceReview } from '../domain/entities/performance-review.entity';
import { PerformanceReviewResponseDto } from './performance-review-response.interface';

/** Never return a raw PerformanceReview entity from a controller — its
 * `employee` relation eager-loads `Employee.user`, which eager-loads
 * `User.passwordHash`. Flattening to this DTO (same convention as
 * RequestResponse/toRequestResponse) keeps that out of every API response. */
export function toPerformanceReviewResponse(
  review: PerformanceReview,
): PerformanceReviewResponseDto {
  return {
    id: review.id,
    employeeId: review.employeeId,
    employeeName: `${review.employee.firstName} ${review.employee.lastName}`,
    employeePhotoUrl: review.employee.profilePhotoUrl ?? null,
    reviewYear: review.reviewYear,
    dueDate: review.dueDate,
    status: review.status,
    responses: [...review.responses]
      .sort((a, b) => a.sortOrder - b.sortOrder)
      .map((response) => ({
        id: response.id,
        criterionId: response.criterionId ?? null,
        criterionName: response.criterionName,
        responseType: response.responseType,
        sortOrder: response.sortOrder,
        ratingValue: response.ratingValue ?? null,
        textValue: response.textValue ?? null,
      })),
    employeeComments: review.employeeComments ?? null,
    completedByName: review.completedByName ?? null,
    completedAt: review.completedAt?.toISOString() ?? null,
    completedAsManager: review.completedAsManager ?? null,
    finalizedByName: review.finalizedByName ?? null,
    finalizedAt: review.finalizedAt?.toISOString() ?? null,
    createdAt: review.createdAt.toISOString(),
  };
}
