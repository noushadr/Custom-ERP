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
  /** What was actually paid — a plain stored figure, not computed from any
   * deduction/addition breakdown (this app has no attendance module and
   * deliberately doesn't track fines/deductions/allowances per line item).
   * Defaults to `baseSalary` when the line item is created, then freely
   * editable for every line item while the run is Draft. */
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
