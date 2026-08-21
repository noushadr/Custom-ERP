import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddProjectPaymentStatus1787600000000 implements MigrationInterface {
  name = 'AddProjectPaymentStatus1787600000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
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

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "projects" DROP COLUMN "amountPaid"`);
    await queryRunner.query(
      `ALTER TABLE "projects" DROP COLUMN "paymentStatus"`,
    );
    await queryRunner.query(`DROP TYPE "project_payment_status_enum"`);
  }
}
