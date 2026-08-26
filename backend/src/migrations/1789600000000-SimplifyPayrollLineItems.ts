import { MigrationInterface, QueryRunner } from 'typeorm';

export class SimplifyPayrollLineItems1789600000000
  implements MigrationInterface
{
  name = 'SimplifyPayrollLineItems1789600000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Net pay becomes a plain, directly-entered figure instead of a
    // computed sum of many small deduction/addition columns — start every
    // existing row off at its current computed net (mirrors the mapper's
    // old formula) before dropping the columns that fed it.
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "netPay" numeric(12,2)`,
    );
    await queryRunner.query(`
      UPDATE "payroll_line_items"
      SET "netPay" = "baseSalary"
        + "allowances" + "overtime" + "reimbursement" + "commissions"
        - "deductions" - "advances" - "tax" - "fines"
    `);
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ALTER COLUMN "netPay" SET NOT NULL`,
    );

    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "allowances"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "overtime"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "reimbursement"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "commissions"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "deductions"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "advances"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "tax"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "fines"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "totalAbsent"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "lateHours"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "lateDays"`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "lateDays" integer NOT NULL DEFAULT 0`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "lateHours" integer NOT NULL DEFAULT 0`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "totalAbsent" integer NOT NULL DEFAULT 0`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "fines" numeric(12,2) NOT NULL DEFAULT '0.00'`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "tax" numeric(12,2) NOT NULL DEFAULT '0.00'`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "advances" numeric(12,2) NOT NULL DEFAULT '0.00'`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "deductions" numeric(12,2) NOT NULL DEFAULT '0.00'`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "commissions" numeric(12,2) NOT NULL DEFAULT '0.00'`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "reimbursement" numeric(12,2) NOT NULL DEFAULT '0.00'`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "overtime" numeric(12,2) NOT NULL DEFAULT '0.00'`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "allowances" numeric(12,2) NOT NULL DEFAULT '0.00'`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "netPay"`,
    );
  }
}
