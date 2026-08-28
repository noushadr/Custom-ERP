import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddNotifications1788000000000 implements MigrationInterface {
  name = 'AddNotifications1788000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "notification_link_target_enum" AS ENUM('clients_projects', 'tasks', 'leave')`,
    );
    await queryRunner.query(
      `CREATE TABLE "notifications" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "recipientUserId" uuid NOT NULL, "message" text NOT NULL, "linkTarget" "notification_link_target_enum", "linkEntityId" character varying, "isRead" boolean NOT NULL DEFAULT false, CONSTRAINT "PK_notifications_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_notifications_recipientUserId" ON "notifications" ("recipientUserId")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "IDX_notifications_recipientUserId"`);
    await queryRunner.query(`DROP TABLE "notifications"`);
    await queryRunner.query(`DROP TYPE "notification_link_target_enum"`);
  }
}
