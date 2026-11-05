import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddAttendance1791600000000 implements MigrationInterface {
  name = 'AddAttendance1791600000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "employees" ADD COLUMN IF NOT EXISTS "attendanceId" character varying`,
    );
    await queryRunner.query(
      `ALTER TABLE "employees" ADD CONSTRAINT "UQ_employees_attendanceId" UNIQUE ("attendanceId")`,
    );
    await queryRunner.query(
      `CREATE TABLE "attendance_punches" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "deviceUserId" character varying NOT NULL, "punchedAt" TIMESTAMP WITH TIME ZONE NOT NULL, CONSTRAINT "UQ_attendance_punch_user_time" UNIQUE ("deviceUserId", "punchedAt"), CONSTRAINT "PK_attendance_punches_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_attendance_punches_punchedAt" ON "attendance_punches" ("punchedAt")`,
    );
    await queryRunner.query(
      `CREATE TABLE "attendance_device_users" ("deviceUserId" character varying NOT NULL, "name" character varying NOT NULL, "ignored" boolean NOT NULL DEFAULT false, CONSTRAINT "PK_attendance_device_users" PRIMARY KEY ("deviceUserId"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "attendance_wfh_days" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "date" character varying(10) NOT NULL, "note" text, CONSTRAINT "UQ_attendance_wfh_days_date" UNIQUE ("date"), CONSTRAINT "PK_attendance_wfh_days_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "attendance_wfh_presence" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "employeeId" uuid NOT NULL, "date" character varying(10) NOT NULL, CONSTRAINT "UQ_wfh_presence_employee_date" UNIQUE ("employeeId", "date"), CONSTRAINT "PK_attendance_wfh_presence_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "attendance_settings" ("id" integer NOT NULL, "shiftStart" character varying(5) NOT NULL DEFAULT '11:00', "shiftEnd" character varying(5) NOT NULL DEFAULT '19:00', "hoursCutAfter" character varying(5) NOT NULL DEFAULT '11:30', "hoursCutFrom" character varying(5) NOT NULL DEFAULT '10:30', "graceMinutes" integer NOT NULL DEFAULT 15, "lastSyncAt" TIMESTAMP WITH TIME ZONE, "lastSyncMessage" text, CONSTRAINT "PK_attendance_settings" PRIMARY KEY ("id"))`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "attendance_wfh_presence"`);
    await queryRunner.query(`DROP TABLE "attendance_wfh_days"`);
    await queryRunner.query(`DROP TABLE "attendance_settings"`);
    await queryRunner.query(`DROP TABLE "attendance_device_users"`);
    await queryRunner.query(`DROP TABLE "attendance_punches"`);
    await queryRunner.query(
      `ALTER TABLE "employees" DROP COLUMN "attendanceId"`,
    );
  }
}
