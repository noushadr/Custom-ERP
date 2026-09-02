import { MigrationInterface, QueryRunner } from 'typeorm';

/** Adds the one new NotificationLinkTarget value needed for "a request
 * needs your approval" notifications sent to a reporting manager. Postgres
 * has no `DROP VALUE` for enums, so `down` can't cleanly reverse this —
 * same documented no-op precedent as
 * AddPerformanceReviewNotificationLinkTarget. */
export class AddRequestsNotificationLinkTarget1789700000000
  implements MigrationInterface
{
  name = 'AddRequestsNotificationLinkTarget1789700000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TYPE "notification_link_target_enum" ADD VALUE 'requests'`,
    );
  }

  public async down(): Promise<void> {
    // No-op: Postgres cannot drop a single enum value.
  }
}
