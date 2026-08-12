import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddLeaveManagement1786200000000 implements MigrationInterface {
  name = 'AddLeaveManagement1786200000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "leave_types" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "name" character varying NOT NULL, "annualAllowanceDays" numeric(5,1) NOT NULL, "carryForwardLimitDays" numeric(5,1), "colorHex" character varying, "isArchived" boolean NOT NULL DEFAULT false, CONSTRAINT "UQ_leave_types_name" UNIQUE ("name"), CONSTRAINT "PK_leave_types_id" PRIMARY KEY ("id"))`,
    );

    await queryRunner.query(
      `CREATE TABLE "leave_balances" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "employeeId" uuid NOT NULL, "leaveTypeId" uuid NOT NULL, "year" integer NOT NULL, "allocated" numeric(5,1) NOT NULL, "used" numeric(5,1) NOT NULL DEFAULT 0, CONSTRAINT "PK_leave_balances_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "IDX_leave_balances_employeeId_leaveTypeId_year" ON "leave_balances" ("employeeId", "leaveTypeId", "year")`,
    );
    await queryRunner.query(
      `ALTER TABLE "leave_balances" ADD CONSTRAINT "FK_leave_balances_employeeId" FOREIGN KEY ("employeeId") REFERENCES "employees"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "leave_balances" ADD CONSTRAINT "FK_leave_balances_leaveTypeId" FOREIGN KEY ("leaveTypeId") REFERENCES "leave_types"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );

    await queryRunner.query(
      `CREATE TYPE "leave_requests_status_enum" AS ENUM('submitted', 'manager_approved', 'approved', 'rejected', 'cancelled')`,
    );
    await queryRunner.query(
      `CREATE TABLE "leave_requests" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "employeeId" uuid NOT NULL, "leaveTypeId" uuid NOT NULL, "startDate" date NOT NULL, "endDate" date NOT NULL, "numberOfDays" numeric(5,1) NOT NULL, "reason" text NOT NULL, "status" "leave_requests_status_enum" NOT NULL DEFAULT 'submitted', "managerDecisionAt" TIMESTAMP WITH TIME ZONE, "managerDecisionByName" character varying, "managerComment" text, "hrDecisionAt" TIMESTAMP WITH TIME ZONE, "hrDecisionByName" character varying, "hrComment" text, "cancelledAt" TIMESTAMP WITH TIME ZONE, CONSTRAINT "PK_leave_requests_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_leave_requests_employeeId" ON "leave_requests" ("employeeId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "leave_requests" ADD CONSTRAINT "FK_leave_requests_employeeId" FOREIGN KEY ("employeeId") REFERENCES "employees"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "leave_requests" ADD CONSTRAINT "FK_leave_requests_leaveTypeId" FOREIGN KEY ("leaveTypeId") REFERENCES "leave_types"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );

    await queryRunner.query(
      `CREATE TABLE "leave_balance_adjustments" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "employeeId" uuid NOT NULL, "leaveTypeId" uuid NOT NULL, "year" integer NOT NULL, "deltaDays" numeric(5,1) NOT NULL, "reason" text NOT NULL, "actorUserId" uuid NOT NULL, "actorName" character varying NOT NULL, CONSTRAINT "PK_leave_balance_adjustments_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_leave_balance_adjustments_employeeId" ON "leave_balance_adjustments" ("employeeId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "leave_balance_adjustments" ADD CONSTRAINT "FK_leave_balance_adjustments_employeeId" FOREIGN KEY ("employeeId") REFERENCES "employees"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "leave_balance_adjustments" ADD CONSTRAINT "FK_leave_balance_adjustments_leaveTypeId" FOREIGN KEY ("leaveTypeId") REFERENCES "leave_types"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "leave_balance_adjustments" DROP CONSTRAINT "FK_leave_balance_adjustments_leaveTypeId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "leave_balance_adjustments" DROP CONSTRAINT "FK_leave_balance_adjustments_employeeId"`,
    );
    await queryRunner.query(
      `DROP INDEX "IDX_leave_balance_adjustments_employeeId"`,
    );
    await queryRunner.query(`DROP TABLE "leave_balance_adjustments"`);

    await queryRunner.query(
      `ALTER TABLE "leave_requests" DROP CONSTRAINT "FK_leave_requests_leaveTypeId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "leave_requests" DROP CONSTRAINT "FK_leave_requests_employeeId"`,
    );
    await queryRunner.query(`DROP INDEX "IDX_leave_requests_employeeId"`);
    await queryRunner.query(`DROP TABLE "leave_requests"`);
    await queryRunner.query(`DROP TYPE "leave_requests_status_enum"`);

    await queryRunner.query(
      `ALTER TABLE "leave_balances" DROP CONSTRAINT "FK_leave_balances_leaveTypeId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "leave_balances" DROP CONSTRAINT "FK_leave_balances_employeeId"`,
    );
    await queryRunner.query(
      `DROP INDEX "IDX_leave_balances_employeeId_leaveTypeId_year"`,
    );
    await queryRunner.query(`DROP TABLE "leave_balances"`);

    await queryRunner.query(`DROP TABLE "leave_types"`);
  }
}
