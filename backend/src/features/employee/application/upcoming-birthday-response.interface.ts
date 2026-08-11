export interface UpcomingBirthdayResponse {
  employeeId: string;
  fullName: string;
  profilePhotoUrl: string | null;
  dateOfBirth: string;
  /** 0 means today. */
  daysUntil: number;
}
