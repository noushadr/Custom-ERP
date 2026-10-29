export interface PerformanceReviewResponseItemDto {
  id: string;
  criterionId: string | null;
  criterionName: string;
  responseType: string;
  sortOrder: number;
  section: string | null;
  hasComment: boolean;
  ratingValue: number | null;
  textValue: string | null;
  commentValue: string | null;
}

export interface PerformanceReviewResponseDto {
  id: string;
  employeeId: string;
  employeeName: string;
  employeePhotoUrl: string | null;
  designation: string | null;
  department: string | null;
  reportingManagerName: string | null;
  reviewYear: number;
  reviewPeriod: number;
  dueDate: string;
  status: string;
  responses: PerformanceReviewResponseItemDto[];
  overallRating: string | null;
  employeeComments: string | null;
  completedByName: string | null;
  completedAt: string | null;
  completedAsManager: boolean | null;
  finalizedByName: string | null;
  finalizedAt: string | null;
  createdAt: string;
}

/** Lightweight per-employee summary for list views (e.g. the employee
 * directory) that only need "when was their last review done" — not the
 * full criterion snapshot `PerformanceReviewResponseDto` carries. */
export interface PerformanceReviewSummaryDto {
  employeeId: string;
  reviewYear: number;
  reviewPeriod: number;
  dueDate: string;
  status: string;
  completedAt: string | null;
  finalizedAt: string | null;
}
