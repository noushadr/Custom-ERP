import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddRenewalReminderTracking1787800000000
  implements MigrationInterface
{
  name = 'AddRenewalReminderTracking1787800000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "projects" ADD "lastRenewalReminderSentFor" date`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "projects" DROP COLUMN "lastRenewalReminderSentFor"`,
    );
  }
}
