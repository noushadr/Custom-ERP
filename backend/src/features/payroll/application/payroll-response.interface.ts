export interface PayrollLineItemResponseDto {
  id: string;
  employeeId: string | null;
  freelancerId: string | null;
  /** `true` when this line item is a freelancer's rather than an
   * employee's — the frontend uses this to decide whether `baseSalary` is
   * directly editable (freelancers) or a read-only snapshot (employees). */
  isFreelancer: boolean;
  employeeName: string;
  employeePhotoUrl: string | null;
  /** The salary snapshot for salaried employees, or `quantity *
   * perUnitRate` for piece-rate employees (see `quantity`/`perUnitRate`
   * below) — whichever this run's effective base pay actually is. */
  baseSalary: number;
  /** Piece-rate units this run; `null` for salaried employees. */
  quantity: number | null;
  perUnitRate: number | null;
  allowances: number;
  overtime: number;
  reimbursement: number;
  commissions: number;
  deductions: number;
  advances: number;
  tax: number;
  fines: number;
  /** Entered count of full absence days this month. */
  totalAbsent: number;
  /** Computed: totalAbsent * (baseSalary / 30). Never stored. */
  absentDeductionRs: number;
  /** Entered count of cumulative late hours this month. */
  lateHours: number;
  /** Computed: lateHours * (baseSalary / 30 / 8). Never stored. */
  lateHoursDeductionRs: number;
  /** Entered count of late-arrival days this month. */
  lateDays: number;
  /** Computed: `floor(lateDays / 3)` unpaid days * (baseSalary / 30).
   * Never stored. */
  lateDaysDeductionRs: number;
  /** Computed: baseSalary + allowances + overtime + reimbursement +
   * commissions - deductions - advances - tax - fines -
   * absentDeductionRs - lateHoursDeductionRs - lateDaysDeductionRs.
   * Never stored. */
  netPay: number;
  notes: string | null;
}

export interface PayrollRunSummaryDto {
  id: string;
  month: number;
  year: number;
  status: string;
  employeeCount: number;
  /** Sum of every line item's netPay. */
  totalNetPay: number;
  generatedByName: string;
  finalizedByName: string | null;
  finalizedAt: string | null;
  paidByName: string | null;
  paidAt: string | null;
  createdAt: string;
}

export interface PayrollRunDetailDto extends PayrollRunSummaryDto {
  lineItems: PayrollLineItemResponseDto[];
}
