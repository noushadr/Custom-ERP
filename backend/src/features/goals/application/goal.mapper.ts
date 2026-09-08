import { EmployeeGoal } from '../domain/entities/employee-goal.entity';
import { GoalResponse } from './goal-response.interface';

export function toGoalResponse(goal: EmployeeGoal): GoalResponse {
  return {
    id: goal.id,
    employeeId: goal.employeeId,
    employeeName: `${goal.employee.firstName} ${goal.employee.lastName}`,
    employeePhotoUrl: goal.employee.profilePhotoUrl ?? null,
    departmentId: goal.employee.departmentId ?? null,
    departmentName: goal.employee.department?.name ?? null,
    title: goal.title,
    description: goal.description ?? null,
    createdByName: goal.createdByName,
    createdAt: goal.createdAt.toISOString(),
  };
}
