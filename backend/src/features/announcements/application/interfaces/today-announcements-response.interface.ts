export interface TodayBirthday {
  employeeId: string;
  fullName: string;
  profilePhotoUrl: string | null;
}

export interface TodayWorkAnniversary {
  employeeId: string;
  fullName: string;
  profilePhotoUrl: string | null;
  yearsOfService: number;
}

export interface TodayHoliday {
  name: string;
  date: string;
}

export interface TodayNotice {
  id: string;
  title: string;
  authorName: string;
}

export interface TodayEmployeeOfMonth {
  employeeId: string;
  fullName: string;
  profilePhotoUrl: string | null;
}

export interface TodayWorkFromHomeNotice {
  /** True when only this viewer was marked, not the whole company. */
  personal: boolean;
  note: string | null;
}

export interface TodayWorkFromHome {
  today: TodayWorkFromHomeNotice | null;
  tomorrow: TodayWorkFromHomeNotice | null;
}

export interface TodayAnnouncementsResponse {
  birthdays: TodayBirthday[];
  workAnniversaries: TodayWorkAnniversary[];
  holiday: TodayHoliday | null;
  notices: TodayNotice[];
  /** Non-null for 7 days after HR/Admin approves an Employee of the Month
   * nomination, then falls away — see `RequestsService.getCurrentEmployeeOfTheMonth`. */
  employeeOfTheMonth: TodayEmployeeOfMonth | null;
  /** Today's / tomorrow's work-from-home day for this viewer, if any. */
  workFromHome: TodayWorkFromHome | null;
}
