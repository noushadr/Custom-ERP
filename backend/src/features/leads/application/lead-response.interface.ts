export interface LeadResponseDto {
  id: string;
  leadDate: string;
  fullName: string;
  companyName: string | null;
  leadSource: string | null;
  phone: string | null;
  email: string | null;
  country: string | null;
  remarks: string | null;
  serviceInterested: string | null;
  isArchived: boolean;
  createdAt: string;
  updatedAt: string;
}
