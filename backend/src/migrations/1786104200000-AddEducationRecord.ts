import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddEducationRecord1786104200000 implements MigrationInterface {
  name = 'AddEducationRecord1786104200000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "employee_education_records" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "employeeId" uuid NOT NULL, "degree" character varying NOT NULL, "institution" character varying NOT NULL, "yearCompleted" integer NOT NULL, CONSTRAINT "PK_employee_education_records_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_employee_education_records_employeeId" ON "employee_education_records" ("employeeId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "employee_education_records" ADD CONSTRAINT "FK_employee_education_records_employeeId" FOREIGN KEY ("employeeId") REFERENCES "employees"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "employee_education_records" DROP CONSTRAINT "FK_employee_education_records_employeeId"`,
    );
    await queryRunner.query(
      `DROP INDEX "IDX_employee_education_records_employeeId"`,
    );
    await queryRunner.query(`DROP TABLE "employee_education_records"`);
  }
}
