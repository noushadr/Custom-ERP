import { MigrationInterface, QueryRunner } from 'typeorm';

export class UpdatePayrollLineItems1789300000000
  implements MigrationInterface
{
  name = 'UpdatePayrollLineItems1789300000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "bonuses"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "fines" numeric(12,2) NOT NULL DEFAULT '0.00'`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "lateCount" integer NOT NULL DEFAULT 0`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "lateCount"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "fines"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "bonuses" numeric(12,2) NOT NULL DEFAULT '0.00'`,
    );
  }
}
