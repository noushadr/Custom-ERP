import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddEmployeeRequests1786106000000 implements MigrationInterface {
  name = 'AddEmployeeRequests1786106000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "employee_requests_status_enum" AS ENUM('submitted', 'manager_approved', 'completed', 'rejected')`,
    );
    await queryRunner.query(
      `CREATE TABLE "employee_requests" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "employeeId" uuid NOT NULL, "subject" character varying NOT NULL, "description" text NOT NULL, "type" character varying, "status" "employee_requests_status_enum" NOT NULL DEFAULT 'submitted', "managerDecisionAt" TIMESTAMP WITH TIME ZONE, "managerDecisionByName" character varying, "hrDecisionAt" TIMESTAMP WITH TIME ZONE, "hrDecisionByName" character varying, "rejectionReason" text, CONSTRAINT "PK_employee_requests_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_employee_requests_employeeId" ON "employee_requests" ("employeeId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "employee_requests" ADD CONSTRAINT "FK_employee_requests_employeeId" FOREIGN KEY ("employeeId") REFERENCES "employees"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "employee_requests" DROP CONSTRAINT "FK_employee_requests_employeeId"`,
    );
    await queryRunner.query(`DROP INDEX "IDX_employee_requests_employeeId"`);
    await queryRunner.query(`DROP TABLE "employee_requests"`);
    await queryRunner.query(`DROP TYPE "employee_requests_status_enum"`);
  }
}
