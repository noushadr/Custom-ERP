import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddEmployeesNotificationLinkTarget1791500000000
  implements MigrationInterface
{
  name = 'AddEmployeesNotificationLinkTarget1791500000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TYPE "notification_link_target_enum" ADD VALUE IF NOT EXISTS 'employees'`,
    );
  }

  public async down(): Promise<void> {
    // Postgres can't drop an enum value; leaving it unused is harmless.
  }
}
