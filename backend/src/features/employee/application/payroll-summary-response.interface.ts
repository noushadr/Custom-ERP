export interface DepartmentPayrollTotal {
  departmentId: string | null;
  departmentName: string;
  totalMonthlyPayroll: number;
  employeeCount: number;
}

export interface PayrollSummaryResponse {
  /** Sum of the current (most recent) salary of every active employee. */
  totalMonthlyPayroll: number;

  /** totalMonthlyPayroll spread evenly across the days in the current
   * calendar month. */
  dailyPayroll: number;

  activeEmployeeCount: number;

  /** totalMonthlyPayroll broken down by each active employee's department,
   * sorted highest total first. Employees with no departmentId are grouped
   * under a single null-id "Unassigned" entry rather than dropped. */
  departmentTotals: DepartmentPayrollTotal[];
}
