import { User } from '../../authentication/domain/entities/user.entity';
import { UserStatus } from '../../authentication/domain/enums/user-status.enum';
import { Employee } from '../domain/entities/employee.entity';
import { EmploymentStatus } from '../domain/enums/employment-status.enum';
import { EmploymentType } from '../domain/enums/employment-type.enum';
import { WorkMode } from '../domain/enums/work-mode.enum';
import { toEmployeeResponse } from './employee.mapper';

function buildEmployee(overrides: Partial<Employee> = {}): Employee {
  return {
    id: 'employee-1',
    employeeCode: 'ZC-00001',
    userId: 'user-1',
    user: {
      email: 'jane.doe@zeracreative.com',
      status: UserStatus.ACTIVE,
      role: { name: 'Employee' },
    } as User,
    firstName: 'Jane',
    lastName: 'Doe',
    employmentType: EmploymentType.FULL_TIME,
    employmentStatus: EmploymentStatus.ACTIVE,
    workMode: WorkMode.ON_SITE,
    joiningDate: '2026-01-01',
    skills: [],
    certifications: [],
    ...overrides,
  } as Employee;
}

describe('toEmployeeResponse — probation status', () => {
  it('is null when no probation end date is on file', () => {
    const response = toEmployeeResponse(buildEmployee());
    expect(response.probationEndDate).toBeNull();
    expect(response.probationStatus).toBeNull();
  });

  it('is "on_probation" when the end date is today or in the future', () => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const response = toEmployeeResponse(
      buildEmployee({
        probationEndDate: tomorrow.toISOString().slice(0, 10),
      }),
    );
    expect(response.probationStatus).toBe('on_probation');
  });

  it('is "completed" once the end date has passed', () => {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const response = toEmployeeResponse(
      buildEmployee({
        probationEndDate: yesterday.toISOString().slice(0, 10),
      }),
    );
    expect(response.probationStatus).toBe('completed');
  });
});
