import { MigrationInterface, QueryRunner } from 'typeorm';

/** Removes pricing/payment tracking from Project entirely, per explicit
 * instruction — no financial tracking remains on Clients & Projects now
 * that Finances/Agency Reporting are gone too. */
export class RemoveProjectPricing1788600000000 implements MigrationInterface {
  name = 'RemoveProjectPricing1788600000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "projects" DROP COLUMN "amountPaid"`);
    await queryRunner.query(
      `ALTER TABLE "projects" DROP COLUMN "paymentStatus"`,
    );
    await queryRunner.query(`DROP TYPE "project_payment_status_enum"`);
    await queryRunner.query(`ALTER TABLE "projects" DROP COLUMN "cost"`);
    await queryRunner.query(
      `ALTER TABLE "projects" DROP COLUMN "deductionRate"`,
    );
    await queryRunner.query(
      `ALTER TABLE "projects" DROP COLUMN "originalClientPrice"`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "projects" ADD "originalClientPrice" numeric(12,2) NOT NULL DEFAULT '0.00'`,
    );
    await queryRunner.query(
      `ALTER TABLE "projects" ADD "deductionRate" numeric(5,2) NOT NULL DEFAULT '20.00'`,
    );
    await queryRunner.query(
      `ALTER TABLE "projects" ADD "cost" numeric(12,2) NOT NULL DEFAULT '0.00'`,
    );
    await queryRunner.query(
      `CREATE TYPE "project_payment_status_enum" AS ENUM('unpaid', 'partial', 'paid')`,
    );
    await queryRunner.query(
      `ALTER TABLE "projects" ADD "paymentStatus" "project_payment_status_enum" NOT NULL DEFAULT 'unpaid'`,
    );
    await queryRunner.query(
      `ALTER TABLE "projects" ADD "amountPaid" numeric(12,2) NOT NULL DEFAULT '0.00'`,
    );
  }
}
