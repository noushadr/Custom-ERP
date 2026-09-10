export interface GoalResponse {
  id: string;
  employeeId: string;
  employeeName: string;
  employeePhotoUrl: string | null;
  departmentId: string | null;
  departmentName: string | null;
  title: string;
  description: string | null;
  achievementPercentage: number;
  createdByName: string;
  createdAt: string;
}
