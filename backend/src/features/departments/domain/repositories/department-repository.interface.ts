import { Department } from '../entities/department.entity';

export const DEPARTMENT_REPOSITORY = Symbol('DEPARTMENT_REPOSITORY');

export interface DepartmentRepository {
  findAll(includeArchived?: boolean): Promise<Department[]>;
  findById(id: string): Promise<Department | null>;
  save(department: Department): Promise<Department>;
  remove(department: Department): Promise<void>;
}
