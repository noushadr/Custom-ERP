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
  /** The salary snapshot (or, for a freelancer, the amount entered). */
  baseSalary: number;
  /** Late arrivals counted from attendance for the month. */
  lateDays: number;
  /** Unpaid days those lates earn. */
  lateDeductionDays: number;
  /** `lateDeductionDays` at `baseSalary / 30` — always 30 calendar days. */
  lateDeduction: number;
  /** Unpaid absent days entered by HR. */
  absentDays: number;
  /** `absentDays` at `baseSalary / 30` each. */
  absentDeduction: number;
  /** Advance salary already paid out, taken off this run. */
  advanceSalary: number;
  /** Hours cut counted from attendance (e.g. 2 = two hours). */
  lateHours: number;
  /** `lateHours` at `baseSalary / 30 / 8` per hour. */
  lateHoursDeduction: number;
  fines: { description: string; amount: number }[];
  finesTotal: number;
  freelanceTasks: { description: string; amount: number }[];
  freelanceTotal: number;
  /** `baseSalary - lateDeduction - lateHoursDeduction - absentDeduction
   * - advanceSalary - finesTotal + freelanceTotal` — computed, not
   * stored. */
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

/** One row of a self-service "my payslips" list — only ever a Paid run's
 * employee line item (never a freelancer's, who has no ERP login to view
 * this from). */
export interface PayslipListItemDto {
  runId: string;
  lineItemId: string;
  month: number;
  year: number;
  netPay: number;
  paidAt: string;
}
