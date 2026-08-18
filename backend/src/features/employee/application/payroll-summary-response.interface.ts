export interface PayrollSummaryResponse {
  /** Sum of the current (most recent) salary of every active employee. */
  totalMonthlyPayroll: number;

  /** totalMonthlyPayroll spread evenly across the days in the current
   * calendar month. */
  dailyPayroll: number;

  activeEmployeeCount: number;
}
