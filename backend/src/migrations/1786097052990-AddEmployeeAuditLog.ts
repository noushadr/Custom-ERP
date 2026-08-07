import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddEmployeeAuditLog1786097052990 implements MigrationInterface {
  name = 'AddEmployeeAuditLog1786097052990';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "employee_audit_logs" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "employeeId" uuid NOT NULL, "actorUserId" uuid NOT NULL, "actorName" character varying NOT NULL, "fieldLabel" character varying NOT NULL, "oldValue" text, "newValue" text, CONSTRAINT "PK_employee_audit_logs_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_employee_audit_logs_employeeId" ON "employee_audit_logs" ("employeeId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "employee_audit_logs" ADD CONSTRAINT "FK_employee_audit_logs_employeeId" FOREIGN KEY ("employeeId") REFERENCES "employees"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "employee_audit_logs" DROP CONSTRAINT "FK_employee_audit_logs_employeeId"`,
    );
    await queryRunner.query(`DROP INDEX "IDX_employee_audit_logs_employeeId"`);
    await queryRunner.query(`DROP TABLE "employee_audit_logs"`);
  }
}
