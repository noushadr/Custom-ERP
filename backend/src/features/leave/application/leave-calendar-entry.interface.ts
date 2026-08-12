export interface LeaveCalendarEntry {
  employeeId: string;
  employeeName: string;
  employeePhotoUrl: string | null;
  leaveTypeId: string;
  leaveTypeName: string;
  colorHex: string | null;
  startDate: string;
  endDate: string;
  /** True while only the manager (not HR/Admin) has approved yet — shown
   * distinctly on the calendar since it isn't final. */
  isPending: boolean;
}
