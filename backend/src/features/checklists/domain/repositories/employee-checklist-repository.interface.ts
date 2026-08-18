import { EmployeeChecklistItem } from '../entities/employee-checklist-item.entity';
import { ChecklistType } from '../enums/checklist-type.enum';

export const EMPLOYEE_CHECKLIST_REPOSITORY = Symbol(
  'EMPLOYEE_CHECKLIST_REPOSITORY',
);

export interface EmployeeChecklistRepository {
  findByEmployeeAndType(
    employeeId: string,
    type: ChecklistType,
  ): Promise<EmployeeChecklistItem[]>;
  findById(id: string): Promise<EmployeeChecklistItem | null>;
  save(item: EmployeeChecklistItem): Promise<EmployeeChecklistItem>;
  saveMany(
    items: EmployeeChecklistItem[],
  ): Promise<EmployeeChecklistItem[]>;
}
