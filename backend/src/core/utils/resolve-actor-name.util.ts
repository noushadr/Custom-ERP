import type { EmployeeRepository } from '../../features/employee/domain/repositories/employee-repository.interface';
import type { UserRepository } from '../../features/authentication/domain/repositories/user-repository.interface';

/** Resolves a display name for whoever performed an action, for denormalized
 * snapshots (audit logs, notices, request decisions). Falls back to the
 * user's email if they have no employee profile (e.g. not yet onboarded). */
export async function resolveActorName(
  employeeRepository: EmployeeRepository,
  userRepository: UserRepository,
  actorUserId: string,
): Promise<string> {
  const employee = await employeeRepository.findByUserId(actorUserId);
  if (employee) return `${employee.firstName} ${employee.lastName}`.trim();
  const user = await userRepository.findById(actorUserId);
  return user?.email ?? 'Unknown';
}
