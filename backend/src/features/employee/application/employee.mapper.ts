import { Employee } from '../domain/entities/employee.entity';
import { EmployeeResponse } from './employee-response.interface';
import { calculateProfileCompletion } from './profile-completion.util';

/** Today vs the stored end date, both compared as plain 'YYYY-MM-DD'
 * strings (no timezone math needed) — matches this codebase's "compute on
 * every read, never store the status itself" convention (netPay, tenure,
 * profitPercent, ...). `null` when no probation period is on file. */
function computeProbationStatus(
  probationEndDate: string | null,
): 'on_probation' | 'completed' | null {
  if (!probationEndDate) return null;
  const today = new Date().toISOString().slice(0, 10);
  return today <= probationEndDate ? 'on_probation' : 'completed';
}

export function toEmployeeResponse(employee: Employee): EmployeeResponse {
  return {
    id: employee.id,
    userId: employee.userId,
    employeeCode: employee.employeeCode,
    email: employee.user.email,
    role: employee.user.role.name,
    accountStatus: employee.user.status,
    firstName: employee.firstName,
    lastName: employee.lastName,
    fullName: `${employee.firstName} ${employee.lastName}`,
    profilePhotoUrl: employee.profilePhotoUrl ?? null,
    designation: employee.designation ?? null,
    department: employee.department
      ? { id: employee.department.id, name: employee.department.name }
      : null,
    reportingManager: employee.reportingManager
      ? {
          id: employee.reportingManager.id,
          name: `${employee.reportingManager.firstName} ${employee.reportingManager.lastName}`,
          photoUrl: employee.reportingManager.profilePhotoUrl ?? null,
        }
      : null,
    employmentType: employee.employmentType,
    employmentStatus: employee.employmentStatus,
    workMode: employee.workMode,
    joiningDate: employee.joiningDate,
    dateOfLeaving: employee.dateOfLeaving ?? null,
    probationEndDate: employee.probationEndDate ?? null,
    probationStatus: computeProbationStatus(employee.probationEndDate ?? null),
    dateOfBirth: employee.dateOfBirth ?? null,
    personalEmail: employee.personalEmail ?? null,
    phoneNumber: employee.phoneNumber ?? null,
    emergencyContactName: employee.emergencyContactName ?? null,
    emergencyContactPhone: employee.emergencyContactPhone ?? null,
    emergencyContactRelation: employee.emergencyContactRelation ?? null,
    address: employee.address ?? null,
    bankName: employee.bankName ?? null,
    accountTitle: employee.accountTitle ?? null,
    accountNumber: employee.accountNumber ?? null,
    branchCode: employee.branchCode ?? null,
    iban: employee.iban ?? null,
    skills: employee.skills,
    certifications: employee.certifications,
    profileCompletionPercentage: calculateProfileCompletion(employee),
  };
}
