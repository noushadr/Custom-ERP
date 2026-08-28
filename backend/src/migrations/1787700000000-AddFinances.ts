import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddFinances1787700000000 implements MigrationInterface {
  name = 'AddFinances1787700000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "expense_category_enum" AS ENUM('rent_utilities', 'software_tools', 'marketing', 'vendor_payment', 'taxes', 'commissions', 'other')`,
    );
    await queryRunner.query(
      `CREATE TABLE "expenses" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "category" "expense_category_enum" NOT NULL, "amount" numeric(12,2) NOT NULL, "date" date NOT NULL, "payeeName" character varying, "notes" text, CONSTRAINT "PK_expenses_id" PRIMARY KEY ("id"))`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "expenses"`);
    await queryRunner.query(`DROP TYPE "expense_category_enum"`);
  }
}
