import { MigrationInterface, QueryRunner } from 'typeorm';

/** Payroll line items: fines become a list of {description, amount} (the old
 * single amount is kept as one "Fine" entry) and `lateHours` is added. */
export class PayrollFinesListLateHours1791900000000 implements MigrationInterface {
  name = 'PayrollFinesListLateHours1791900000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "lateHours" numeric(6,2) NOT NULL DEFAULT '0.00', ADD "finesList" jsonb NOT NULL DEFAULT '[]'`,
    );
    await queryRunner.query(
      `UPDATE "payroll_line_items" SET "finesList" = jsonb_build_array(jsonb_build_object('description', 'Fine', 'amount', "fines"::float)) WHERE "fines" > 0`,
    );
    await queryRunner.query(`ALTER TABLE "payroll_line_items" DROP COLUMN "fines"`);
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" RENAME COLUMN "finesList" TO "fines"`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "finesTotal" numeric(12,2) NOT NULL DEFAULT '0.00'`,
    );
    await queryRunner.query(
      `UPDATE "payroll_line_items" SET "finesTotal" = COALESCE((SELECT SUM((e->>'amount')::numeric) FROM jsonb_array_elements("fines") e), 0)`,
    );
    await queryRunner.query(`ALTER TABLE "payroll_line_items" DROP COLUMN "fines"`);
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" RENAME COLUMN "finesTotal" TO "fines"`,
    );
    await queryRunner.query(`ALTER TABLE "payroll_line_items" DROP COLUMN "lateHours"`);
  }
}
