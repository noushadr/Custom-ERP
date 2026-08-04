import { EmploymentStatus } from '../domain/enums/employment-status.enum';
import { EmploymentType } from '../domain/enums/employment-type.enum';

export interface EmployeeResponse {
  id: string;
  employeeCode: string;
  email: string;
  role: string;
  accountStatus: string;
  firstName: string;
  lastName: string;
  fullName: string;
  profilePhotoUrl: string | null;
  designation: string | null;
  department: { id: string; name: string } | null;
  team: { id: string; name: string } | null;
  reportingManagerId: string | null;
  employmentType: EmploymentType;
  employmentStatus: EmploymentStatus;
  joiningDate: string;
  personalEmail: string | null;
  phoneNumber: string | null;
  emergencyContactName: string | null;
  emergencyContactPhone: string | null;
  emergencyContactRelation: string | null;
  address: string | null;
  skills: string[];
  certifications: string[];
  profileCompletionPercentage: number;
}
