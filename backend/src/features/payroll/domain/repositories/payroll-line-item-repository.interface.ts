import { PayrollLineItem } from '../entities/payroll-line-item.entity';

export const PAYROLL_LINE_ITEM_REPOSITORY = Symbol(
  'PAYROLL_LINE_ITEM_REPOSITORY',
);

export interface PayrollLineItemRepository {
  findByRunId(runId: string): Promise<PayrollLineItem[]>;
  findById(id: string): Promise<PayrollLineItem | null>;
  save(item: PayrollLineItem): Promise<PayrollLineItem>;
  saveMany(items: PayrollLineItem[]): Promise<PayrollLineItem[]>;
}
