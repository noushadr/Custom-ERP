import { Employee } from '../entities/employee.entity';

export const EMPLOYEE_REPOSITORY = Symbol('EMPLOYEE_REPOSITORY');

export interface EmployeeRepository {
  findAll(): Promise<Employee[]>;
  findById(id: string): Promise<Employee | null>;
  findByUserId(userId: string): Promise<Employee | null>;
  findByReportingManagerId(managerId: string): Promise<Employee[]>;
  count(): Promise<number>;
  save(employee: Employee): Promise<Employee>;
}
