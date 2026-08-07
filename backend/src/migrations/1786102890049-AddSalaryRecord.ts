import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddSalaryRecord1786102890049 implements MigrationInterface {
  name = 'AddSalaryRecord1786102890049';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "employee_salary_records" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "employeeId" uuid NOT NULL, "amount" numeric(12,2) NOT NULL, "effectiveDate" date NOT NULL, "note" character varying, CONSTRAINT "PK_employee_salary_records_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_employee_salary_records_employeeId" ON "employee_salary_records" ("employeeId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "employee_salary_records" ADD CONSTRAINT "FK_employee_salary_records_employeeId" FOREIGN KEY ("employeeId") REFERENCES "employees"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "employee_salary_records" DROP CONSTRAINT "FK_employee_salary_records_employeeId"`,
    );
    await queryRunner.query(
      `DROP INDEX "IDX_employee_salary_records_employeeId"`,
    );
    await queryRunner.query(`DROP TABLE "employee_salary_records"`);
  }
}
