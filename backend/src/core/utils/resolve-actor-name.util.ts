import type { EmployeeRepository } from '../../features/employee/domain/repositories/employee-repository.interface';
import type { UserRepository } from '../../features/authentication/domain/repositories/user-repository.interface';

/** Resolves a display name for whoever performed an action, for denormalized
 * snapshots (audit logs, notices, request decisions). Actions taken by a
 * login with no employee profile (e.g. a bootstrap Super Admin account) fall
 * back to a name derived from their email's local part rather than the raw
 * address, since a changelog should always read as "done by a person." */
export async function resolveActorName(
  employeeRepository: EmployeeRepository,
  userRepository: UserRepository,
  actorUserId: string,
): Promise<string> {
  const employee = await employeeRepository.findByUserId(actorUserId);
  if (employee) return `${employee.firstName} ${employee.lastName}`.trim();
  const user = await userRepository.findById(actorUserId);
  if (!user) return 'Unknown';
  return nameFromEmail(user.email);
}

function nameFromEmail(email: string): string {
  const localPart = email.split('@')[0] ?? email;
  const words = localPart.split(/[._-]+/).filter(Boolean);
  if (words.length === 0) return email;
  return words
    .map((word) => word[0].toUpperCase() + word.slice(1).toLowerCase())
    .join(' ');
}
