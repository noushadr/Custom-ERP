export interface UpcomingWorkAnniversaryResponse {
  employeeId: string;
  fullName: string;
  profilePhotoUrl: string | null;
  joiningDate: string;
  /** 0 means today; negative means the anniversary already happened this
   * many days ago; positive means it's this many days away. */
  daysUntil: number;
  /** Full years of service being marked, e.g. 3 for a 3rd anniversary. */
  yearsOfService: number;
}
