import type { Employee } from '../../features/employee/domain/entities/employee.entity';
import type { EmployeeRepository } from '../../features/employee/domain/repositories/employee-repository.interface';
import type { User } from '../../features/authentication/domain/entities/user.entity';
import type { UserRepository } from '../../features/authentication/domain/repositories/user-repository.interface';
import { resolveActorName } from './resolve-actor-name.util';

function buildRepos(overrides: {
  employee?: Partial<Employee> | null;
  user?: Partial<User> | null;
}) {
  const employeeRepository = {
    findByUserId: jest.fn().mockResolvedValue(overrides.employee ?? null),
  } as unknown as EmployeeRepository;
  const userRepository = {
    findById: jest.fn().mockResolvedValue(overrides.user ?? null),
  } as unknown as UserRepository;
  return { employeeRepository, userRepository };
}

describe('resolveActorName', () => {
  it("returns the employee's full name when the actor has a profile", async () => {
    const { employeeRepository, userRepository } = buildRepos({
      employee: { firstName: 'Jane', lastName: 'Doe' },
    });

    const name = await resolveActorName(
      employeeRepository,
      userRepository,
      'user-1',
    );

    expect(name).toBe('Jane Doe');
  });

  it('derives a display name from a dotted email local part when there is no employee profile', async () => {
    const { employeeRepository, userRepository } = buildRepos({
      employee: null,
      user: { email: 'noushad.ranani@zeracreative.com' },
    });

    const name = await resolveActorName(
      employeeRepository,
      userRepository,
      'user-2',
    );

    expect(name).toBe('Noushad Ranani');
  });

  it('title-cases a single-word local part when there is no separator', async () => {
    const { employeeRepository, userRepository } = buildRepos({
      employee: null,
      user: { email: 'noushad@zeracreative.com' },
    });

    const name = await resolveActorName(
      employeeRepository,
      userRepository,
      'user-3',
    );

    expect(name).toBe('Noushad');
  });

  it('returns "Unknown" when neither an employee nor a user is found', async () => {
    const { employeeRepository, userRepository } = buildRepos({
      employee: null,
      user: null,
    });

    const name = await resolveActorName(
      employeeRepository,
      userRepository,
      'missing',
    );

    expect(name).toBe('Unknown');
  });
});
