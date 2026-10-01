import { MigrationInterface, QueryRunner } from 'typeorm';

/** Adds a nullable `category` column to the existing `notifications` table
 * (nullable since historical rows predate this feature and shouldn't be
 * guessed at — see the entity's own doc comment) and a new flat
 * `notification_mute_preferences` table, one row per muted (userId,
 * category) pair. */
export class AddNotificationCategoryAndMutePreferences1790400000000
  implements MigrationInterface
{
  name = 'AddNotificationCategoryAndMutePreferences1790400000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "notification_category_enum" AS ENUM (
        'task_progress_update',
        'task_deadline_reminder',
        'request_awaiting_approval',
        'employee_of_month',
        'performance_review_created',
        'performance_review_action_needed',
        'leave_applied_for_you',
        'leave_balance_reset',
        'leave_reset_admin_summary',
        'payroll_paid'
      )`,
    );
    await queryRunner.query(
      `ALTER TABLE "notifications" ADD "category" "notification_category_enum"`,
    );

    await queryRunner.query(
      `CREATE TABLE "notification_mute_preferences" (
        "id" uuid NOT NULL,
        "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "userId" character varying NOT NULL,
        "category" "notification_category_enum" NOT NULL,
        CONSTRAINT "UQ_notification_mute_preferences_userId_category" UNIQUE ("userId", "category"),
        CONSTRAINT "PK_notification_mute_preferences" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_notification_mute_preferences_userId" ON "notification_mute_preferences" ("userId")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "notification_mute_preferences"`);
    await queryRunner.query(
      `ALTER TABLE "notifications" DROP COLUMN "category"`,
    );
    await queryRunner.query(`DROP TYPE "notification_category_enum"`);
  }
}
