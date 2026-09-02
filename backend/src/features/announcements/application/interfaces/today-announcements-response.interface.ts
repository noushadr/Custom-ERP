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

export interface TodayAnnouncementsResponse {
  birthdays: TodayBirthday[];
  workAnniversaries: TodayWorkAnniversary[];
  holiday: TodayHoliday | null;
  notices: TodayNotice[];
}
