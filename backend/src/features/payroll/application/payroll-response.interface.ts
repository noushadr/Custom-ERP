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
  /** A one-off amount added on top of `baseSalary` this run — freely
   * editable while the run is Draft, defaults to 0. */
  additions: number;
  /** A one-off amount subtracted from `baseSalary` this run — freely
   * editable while the run is Draft, defaults to 0. */
  deductions: number;
  /** `baseSalary + additions - deductions` — computed here, not stored
   * (this app deliberately has no attendance module or itemized
   * fines/allowances breakdown beyond this one addition/deduction pair). */
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

export interface PayrollDepartmentTotal {
  departmentId: string | null;
  /** "Unassigned" for an employee with no department, "Freelancers" for
   * every freelancer line item grouped together (freelancers don't belong
   * to a department at all). */
  departmentName: string;
  totalNetPay: number;
  itemCount: number;
}

export interface PayrollRunDetailDto extends PayrollRunSummaryDto {
  lineItems: PayrollLineItemResponseDto[];
  /** This run's totalNetPay broken down by department, sorted
   * highest-total first. */
  departmentTotals: PayrollDepartmentTotal[];
}
