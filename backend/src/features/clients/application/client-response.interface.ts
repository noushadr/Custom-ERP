export interface ClientResponseDto {
  id: string;
  companyName: string;
  industry: string | null;
  website: string | null;
  address: string | null;
  primaryContactName: string | null;
  primaryContactEmail: string | null;
  primaryContactPhone: string | null;
  notes: string | null;
  isArchived: boolean;
  archivedAt: string | null;
  healthStatus: string;
  healthFactors: string[];
  healthNotes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface ClientHealthHistoryResponseDto {
  id: string;
  clientId: string;
  previousStatus: string;
  newStatus: string;
  factors: string[];
  notes: string | null;
  actorName: string;
  createdAt: string;
}

export interface ClientHealthSummaryDto {
  healthyCount: number;
  attentionRequiredCount: number;
  atRiskCount: number;
}

export interface ServiceResponseDto {
  id: string;
  name: string;
  description: string | null;
  isArchived: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface ProjectEmployeeRef {
  id: string;
  fullName: string;
  photoUrl: string | null;
}

export interface ProjectDepartmentRef {
  id: string;
  name: string;
}

export interface ProjectServiceRef {
  id: string;
  name: string;
}

export interface ProjectResponseDto {
  id: string;
  clientId: string;
  clientName: string;
  name: string;
  type: string;
  status: string;
  startDate: string;
  endDate: string | null;
  renewalDate: string | null;
  originalClientPrice: number;
  deductionRate: number;
  /** Computed: originalClientPrice * (1 - deductionRate / 100) — never
   * stored, always derived fresh. */
  netPrice: number;
  cost: number;
  /** Computed: netPrice - cost. */
  profit: number;
  notes: string | null;
  paymentStatus: string;
  amountPaid: number;
  assignedEmployees: ProjectEmployeeRef[];
  targetDepartments: ProjectDepartmentRef[];
  services: ProjectServiceRef[];
  createdAt: string;
  updatedAt: string;
}

export interface ProjectsSummaryDto {
  activeCount: number;
  onHoldCount: number;
  completedCount: number;
  cancelledCount: number;
  /** Sum of netPrice for every active retainer project — a proxy for
   * current monthly recurring revenue. */
  activeMonthlyRecurringRevenue: number;
  /** Sum of netPrice for every one-time project started this calendar
   * year. */
  oneTimeRevenueThisYear: number;
}
