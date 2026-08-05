import { Employee } from '../domain/entities/employee.entity';
import { EmployeeResponse } from './employee-response.interface';
import { calculateProfileCompletion } from './profile-completion.util';

export function toEmployeeResponse(employee: Employee): EmployeeResponse {
  return {
    id: employee.id,
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
    team: employee.team
      ? { id: employee.team.id, name: employee.team.name }
      : null,
    reportingManager: employee.reportingManager
      ? {
          id: employee.reportingManager.id,
          name: `${employee.reportingManager.firstName} ${employee.reportingManager.lastName}`,
        }
      : null,
    employmentType: employee.employmentType,
    employmentStatus: employee.employmentStatus,
    workMode: employee.workMode,
    joiningDate: employee.joiningDate,
    dateOfLeaving: employee.dateOfLeaving ?? null,
    dateOfBirth: employee.dateOfBirth ?? null,
    personalEmail: employee.personalEmail ?? null,
    phoneNumber: employee.phoneNumber ?? null,
    emergencyContactName: employee.emergencyContactName ?? null,
    emergencyContactPhone: employee.emergencyContactPhone ?? null,
    emergencyContactRelation: employee.emergencyContactRelation ?? null,
    address: employee.address ?? null,
    skills: employee.skills,
    certifications: employee.certifications,
    profileCompletionPercentage: calculateProfileCompletion(employee),
  };
}
