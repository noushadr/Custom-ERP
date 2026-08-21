import { Column, Entity } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { ExpenseCategory } from '../enums/expense-category.enum';

/** A single expense record — the unified model for both general expenses
 * and vendor payments (a vendor payment is just an expense with `payeeName`
 * filled in and category VENDOR_PAYMENT), per the confirmed decision not to
 * build a separate Vendor catalog for v1. */
@Entity('expenses')
export class Expense extends BaseEntity {
  @Column({ type: 'enum', enum: ExpenseCategory, enumName: 'expense_category_enum' })
  category: ExpenseCategory;

  @Column({ type: 'numeric', precision: 12, scale: 2 })
  amount: string;

  @Column({ type: 'date' })
  date: string;

  @Column({ nullable: true })
  payeeName?: string;

  @Column({ type: 'text', nullable: true })
  notes?: string;
}
