import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddDocumentType1786096925991 implements MigrationInterface {
  name = 'AddDocumentType1786096925991';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "employee_documents_documenttype_enum" AS ENUM('contract', 'resume', 'cnic', 'other')`,
    );
    await queryRunner.query(
      `ALTER TABLE "employee_documents" ADD "documentType" "employee_documents_documenttype_enum" NOT NULL DEFAULT 'other'`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "employee_documents" DROP COLUMN "documentType"`,
    );
    await queryRunner.query(`DROP TYPE "employee_documents_documenttype_enum"`);
  }
}
