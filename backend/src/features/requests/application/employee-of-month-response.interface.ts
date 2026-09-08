export interface EmployeeOfMonthResponse {
  employeeId: string;
  fullName: string;
  profilePhotoUrl: string | null;
  /** When HR/Admin approved this nomination — the banner stops showing it
   * once 7 days have passed since this moment. */
  approvedAt: string;
}
