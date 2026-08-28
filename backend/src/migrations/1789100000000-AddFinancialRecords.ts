import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddFinancialRecords1789100000000 implements MigrationInterface {
  name = 'AddFinancialRecords1789100000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "financial_records" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "year" integer NOT NULL, "month" integer NOT NULL, "revenueRs" numeric(14,2) NOT NULL, "revenueUsd" numeric(14,2) NOT NULL, "expenseRs" numeric(14,2) NOT NULL, "expenseUsd" numeric(14,2) NOT NULL, "fxRate" numeric(8,2) NOT NULL, CONSTRAINT "UQ_financial_records_year_month" UNIQUE ("year", "month"), CONSTRAINT "PK_financial_records_id" PRIMARY KEY ("id"))`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "financial_records"`);
  }
}
