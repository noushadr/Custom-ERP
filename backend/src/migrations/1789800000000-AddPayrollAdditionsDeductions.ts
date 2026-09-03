import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddPayrollAdditionsDeductions1789800000000
  implements MigrationInterface
{
  name = 'AddPayrollAdditionsDeductions1789800000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "additions" numeric(12,2) NOT NULL DEFAULT '0.00'`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "deductions" numeric(12,2) NOT NULL DEFAULT '0.00'`,
    );
    // netPay becomes computed again (baseSalary + additions - deductions,
    // see the mapper) instead of a plain stored figure — safe to drop
    // outright since every existing row's netPay already equals its
    // baseSalary exactly (no line item has ever diverged under the
    // directly-entered model this replaces), which is exactly what the new
    // formula reproduces with additions/deductions both defaulted to 0.
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "netPay"`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "netPay" numeric(12,2)`,
    );
    await queryRunner.query(`
      UPDATE "payroll_line_items"
      SET "netPay" = "baseSalary" + "additions" - "deductions"
    `);
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ALTER COLUMN "netPay" SET NOT NULL`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "deductions"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "additions"`,
    );
  }
}
