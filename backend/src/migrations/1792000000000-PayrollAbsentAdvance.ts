import { MigrationInterface, QueryRunner } from 'typeorm';

/** Payroll line items: manual absent days (salary / 30 each) and advance
 * salary taken off the run. */
export class PayrollAbsentAdvance1792000000000 implements MigrationInterface {
  name = 'PayrollAbsentAdvance1792000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "absentDays" integer NOT NULL DEFAULT 0, ADD "advanceSalary" numeric(12,2) NOT NULL DEFAULT '0.00'`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "absentDays", DROP COLUMN "advanceSalary"`,
    );
  }
}
