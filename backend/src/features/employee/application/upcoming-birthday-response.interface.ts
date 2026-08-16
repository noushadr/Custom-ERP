export interface UpcomingBirthdayResponse {
  employeeId: string;
  fullName: string;
  profilePhotoUrl: string | null;
  dateOfBirth: string;
  /** 0 means today; negative means the birthday already happened this many
   * days ago; positive means it's this many days away. */
  daysUntil: number;
}
