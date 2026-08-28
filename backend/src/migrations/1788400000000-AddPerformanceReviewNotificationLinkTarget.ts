import { MigrationInterface, QueryRunner } from 'typeorm';

/** Adds the one new NotificationLinkTarget value needed for the
 * performance-review "your review has been created"/"ready to rate"
 * notifications. Postgres has no `DROP VALUE` for enums, so `down` can't
 * cleanly reverse this — it's a documented no-op rather than a
 * type-recreate, since no other migration in this project needs to run
 * after a rollback that would conflict with the extra value sitting
 * unused. */
export class AddPerformanceReviewNotificationLinkTarget1788400000000
  implements MigrationInterface
{
  name = 'AddPerformanceReviewNotificationLinkTarget1788400000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TYPE "notification_link_target_enum" ADD VALUE 'performance_reviews'`,
    );
  }

  public async down(): Promise<void> {
    // No-op: Postgres cannot drop a single enum value.
  }
}
