import { Employee } from '../domain/entities/employee.entity';

const TRACKED_FIELDS: Array<(employee: Employee) => boolean> = [
  (e) => !!e.profilePhotoUrl,
  (e) => !!e.designation,
  (e) => !!e.departmentId,
  (e) => !!e.teamId,
  (e) => !!e.reportingManagerId,
  (e) => !!e.personalEmail,
  (e) => !!e.phoneNumber,
  (e) => !!e.dateOfBirth,
  (e) => !!e.emergencyContactName,
  (e) => !!e.emergencyContactPhone,
  (e) => !!e.address,
  (e) => e.skills.length > 0,
  (e) => e.certifications.length > 0,
];

/** Percentage (0-100) of optional profile fields that have been filled in. */
export function calculateProfileCompletion(employee: Employee): number {
  const filled = TRACKED_FIELDS.filter((check) => check(employee)).length;
  return Math.round((filled / TRACKED_FIELDS.length) * 100);
}
