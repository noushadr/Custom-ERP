import { PayrollRun } from '../entities/payroll-run.entity';

export const PAYROLL_RUN_REPOSITORY = Symbol('PAYROLL_RUN_REPOSITORY');

export interface PayrollRunRepository {
  findAll(): Promise<PayrollRun[]>;
  findById(id: string): Promise<PayrollRun | null>;
  findByMonthYear(month: number, year: number): Promise<PayrollRun | null>;
  save(run: PayrollRun): Promise<PayrollRun>;
}
