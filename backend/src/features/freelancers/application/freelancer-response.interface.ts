export interface FreelancerResponseDto {
  id: string;
  fullName: string;
  role: string | null;
  notes: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}
