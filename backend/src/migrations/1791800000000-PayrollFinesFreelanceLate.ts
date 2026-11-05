import { MigrationInterface, QueryRunner } from 'typeorm';

/** Payroll line items: drop the generic additions/deductions and the
 * piece-rate quantity/rate; add attendance-driven late days, fines and
 * freelance tasks. Existing additions/deductions are folded into `fines`
 * (deductions) and a freelance task (additions) so no figure is lost. */
export class PayrollFinesFreelanceLate1791800000000 implements MigrationInterface {
  name = 'PayrollFinesFreelanceLate1791800000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "lateDays" integer NOT NULL DEFAULT 0, ADD "lateDeductionDays" integer NOT NULL DEFAULT 0, ADD "fines" numeric(12,2) NOT NULL DEFAULT '0.00', ADD "freelanceTasks" jsonb NOT NULL DEFAULT '[]'`,
    );
    await queryRunner.query(
      `UPDATE "payroll_line_items" SET "fines" = "deductions" WHERE "deductions" > 0`,
    );
    await queryRunner.query(
      `UPDATE "payroll_line_items" SET "freelanceTasks" = jsonb_build_array(jsonb_build_object('description', 'Addition', 'amount', "additions"::float)) WHERE "additions" > 0`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "quantity", DROP COLUMN "perUnitRate", DROP COLUMN "additions", DROP COLUMN "deductions"`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "quantity" integer, ADD "perUnitRate" numeric(12,2), ADD "additions" numeric(12,2) NOT NULL DEFAULT '0.00', ADD "deductions" numeric(12,2) NOT NULL DEFAULT '0.00'`,
    );
    await queryRunner.query(
      `UPDATE "payroll_line_items" SET "deductions" = "fines"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "lateDays", DROP COLUMN "lateDeductionDays", DROP COLUMN "fines", DROP COLUMN "freelanceTasks"`,
    );
  }
}
