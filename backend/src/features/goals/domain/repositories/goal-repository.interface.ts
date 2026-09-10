import { EmployeeGoal } from '../entities/employee-goal.entity';

export const GOAL_REPOSITORY = Symbol('GOAL_REPOSITORY');

export interface GoalRepository {
  findAll(): Promise<EmployeeGoal[]>;
  findById(id: string): Promise<EmployeeGoal | null>;
  findByEmployeeId(employeeId: string): Promise<EmployeeGoal[]>;
  save(goal: EmployeeGoal): Promise<EmployeeGoal>;
  saveMany(goals: EmployeeGoal[]): Promise<EmployeeGoal[]>;
}
