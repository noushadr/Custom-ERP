import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddPayrollAttendanceAndPieceRateFields1789400000000
  implements MigrationInterface
{
  name = 'AddPayrollAttendanceAndPieceRateFields1789400000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" RENAME COLUMN "lateCount" TO "lateDays"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "quantity" integer`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "perUnitRate" numeric(12,2)`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "reimbursement" numeric(12,2) NOT NULL DEFAULT '0.00'`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "commissions" numeric(12,2) NOT NULL DEFAULT '0.00'`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "totalAbsent" integer NOT NULL DEFAULT 0`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "lateHours" integer NOT NULL DEFAULT 0`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "lateHours"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "totalAbsent"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "commissions"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "reimbursement"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "perUnitRate"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "quantity"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" RENAME COLUMN "lateDays" TO "lateCount"`,
    );
  }
}
