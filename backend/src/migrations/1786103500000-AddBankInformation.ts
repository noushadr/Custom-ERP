import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddBankInformation1786103500000 implements MigrationInterface {
  name = 'AddBankInformation1786103500000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "employees" ADD "bankName" character varying`,
    );
    await queryRunner.query(
      `ALTER TABLE "employees" ADD "accountTitle" character varying`,
    );
    await queryRunner.query(
      `ALTER TABLE "employees" ADD "accountNumber" character varying`,
    );
    await queryRunner.query(
      `ALTER TABLE "employees" ADD "branchCode" character varying`,
    );
    await queryRunner.query(
      `ALTER TABLE "employees" ADD "iban" character varying`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "employees" DROP COLUMN "iban"`);
    await queryRunner.query(`ALTER TABLE "employees" DROP COLUMN "branchCode"`);
    await queryRunner.query(
      `ALTER TABLE "employees" DROP COLUMN "accountNumber"`,
    );
    await queryRunner.query(
      `ALTER TABLE "employees" DROP COLUMN "accountTitle"`,
    );
    await queryRunner.query(`ALTER TABLE "employees" DROP COLUMN "bankName"`);
  }
}
