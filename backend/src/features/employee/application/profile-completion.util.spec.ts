import { Employee } from '../domain/entities/employee.entity';
import { calculateProfileCompletion } from './profile-completion.util';

function buildEmployee(overrides: Partial<Employee> = {}): Employee {
  return {
    skills: [],
    certifications: [],
    ...overrides,
  } as Employee;
}

describe('calculateProfileCompletion', () => {
  it('returns 0 when no optional fields are filled', () => {
    expect(calculateProfileCompletion(buildEmployee())).toBe(0);
  });

  it('returns 100 when every tracked field is filled', () => {
    const employee = buildEmployee({
      profilePhotoUrl: 'https://example.com/photo.jpg',
      designation: 'Software Engineer',
      departmentId: 'dept-1',
      teamId: 'team-1',
      reportingManagerId: 'manager-1',
      personalEmail: 'jane@example.com',
      phoneNumber: '+1234567890',
      emergencyContactName: 'John Doe',
      emergencyContactPhone: '+1234567891',
      address: '123 Main St',
      skills: ['TypeScript'],
      certifications: ['AWS Certified'],
    });

    expect(calculateProfileCompletion(employee)).toBe(100);
  });

  it('returns a partial percentage when some fields are filled', () => {
    const employee = buildEmployee({
      designation: 'Software Engineer',
      departmentId: 'dept-1',
    });

    const result = calculateProfileCompletion(employee);
    expect(result).toBeGreaterThan(0);
    expect(result).toBeLessThan(100);
  });
});
