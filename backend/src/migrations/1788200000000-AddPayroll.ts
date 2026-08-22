import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddPayroll1788200000000 implements MigrationInterface {
  name = 'AddPayroll1788200000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "payroll_run_status_enum" AS ENUM('draft', 'finalized', 'paid')`,
    );

    await queryRunner.query(
      `CREATE TABLE "payroll_runs" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "month" integer NOT NULL, "year" integer NOT NULL, "status" "payroll_run_status_enum" NOT NULL DEFAULT 'draft', "generatedByName" character varying NOT NULL, "finalizedByName" character varying, "finalizedAt" TIMESTAMP WITH TIME ZONE, "paidByName" character varying, "paidAt" TIMESTAMP WITH TIME ZONE, CONSTRAINT "UQ_payroll_runs_month_year" UNIQUE ("month", "year"), CONSTRAINT "PK_payroll_runs_id" PRIMARY KEY ("id"))`,
    );

    await queryRunner.query(
      `CREATE TABLE "payroll_line_items" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "runId" uuid NOT NULL, "employeeId" uuid NOT NULL, "baseSalary" numeric(12,2) NOT NULL, "bonuses" numeric(12,2) NOT NULL DEFAULT '0.00', "allowances" numeric(12,2) NOT NULL DEFAULT '0.00', "overtime" numeric(12,2) NOT NULL DEFAULT '0.00', "deductions" numeric(12,2) NOT NULL DEFAULT '0.00', "advances" numeric(12,2) NOT NULL DEFAULT '0.00', "tax" numeric(12,2) NOT NULL DEFAULT '0.00', "notes" text, CONSTRAINT "PK_payroll_line_items_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_payroll_line_items_runId" ON "payroll_line_items" ("runId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD CONSTRAINT "FK_payroll_line_items_runId" FOREIGN KEY ("runId") REFERENCES "payroll_runs"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP CONSTRAINT "FK_payroll_line_items_runId"`,
    );
    await queryRunner.query(`DROP INDEX "IDX_payroll_line_items_runId"`);
    await queryRunner.query(`DROP TABLE "payroll_line_items"`);
    await queryRunner.query(`DROP TABLE "payroll_runs"`);
    await queryRunner.query(`DROP TYPE "payroll_run_status_enum"`);
  }
}
