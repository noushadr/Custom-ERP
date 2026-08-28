import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddTaskDeadlineReminderTracking1787900000000
  implements MigrationInterface
{
  name = 'AddTaskDeadlineReminderTracking1787900000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "tasks" ADD "lastDeadlineReminderSentFor" date`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "tasks" DROP COLUMN "lastDeadlineReminderSentFor"`,
    );
  }
}
