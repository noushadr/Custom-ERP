import { MigrationInterface, QueryRunner } from 'typeorm';

/** Removes the Automations feature entirely — its 3 admin-toggleable
 * behaviors are replaced by unconditional, hardcoded notifications inside
 * TasksService (deadline reminders) and LeaveService (annual reset).
 * Project Renewal Reminder has no replacement — it only ever notified
 * `clients.manage` holders, not the employees it concerned, so it doesn't
 * fit the "make sure everyone is notified" goal this migration serves; its
 * idempotency column is dropped along with it. */
export class RemoveAutomations1788300000000 implements MigrationInterface {
  name = 'RemoveAutomations1788300000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX "IDX_automation_execution_history_type_createdAt"`,
    );
    await queryRunner.query(`DROP TABLE "automation_execution_history"`);
    await queryRunner.query(`DROP TABLE "automations"`);

    await queryRunner.query(`DROP TYPE "automation_run_status_enum"`);
    await queryRunner.query(`DROP TYPE "automation_run_trigger_enum"`);
    await queryRunner.query(`DROP TYPE "automation_type_enum"`);

    await queryRunner.query(
      `ALTER TABLE "projects" DROP COLUMN "lastRenewalReminderSentFor"`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "projects" ADD "lastRenewalReminderSentFor" date`,
    );

    await queryRunner.query(
      `CREATE TYPE "automation_type_enum" AS ENUM('project_renewal_reminder', 'task_deadline_reminder', 'annual_leave_reset')`,
    );
    await queryRunner.query(
      `CREATE TYPE "automation_run_trigger_enum" AS ENUM('cron', 'manual')`,
    );
    await queryRunner.query(
      `CREATE TYPE "automation_run_status_enum" AS ENUM('success', 'error')`,
    );

    await queryRunner.query(
      `CREATE TABLE "automations" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "type" "automation_type_enum" NOT NULL, "isActive" boolean NOT NULL DEFAULT false, "daysBefore" integer DEFAULT 7, "updatedByName" character varying, CONSTRAINT "UQ_automations_type" UNIQUE ("type"), CONSTRAINT "PK_automations_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "automation_execution_history" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "type" "automation_type_enum" NOT NULL, "triggeredBy" "automation_run_trigger_enum" NOT NULL, "status" "automation_run_status_enum" NOT NULL, "itemsProcessed" integer NOT NULL DEFAULT 0, "notificationsCreated" integer NOT NULL DEFAULT 0, "errorMessage" text, CONSTRAINT "PK_automation_execution_history_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_automation_execution_history_type_createdAt" ON "automation_execution_history" ("type", "createdAt")`,
    );
  }
}
