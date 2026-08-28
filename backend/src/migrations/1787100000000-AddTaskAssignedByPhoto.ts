import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddTaskAssignedByPhoto1787100000000
  implements MigrationInterface
{
  name = 'AddTaskAssignedByPhoto1787100000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "tasks" ADD "assignedByPhotoUrl" character varying`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "tasks" DROP COLUMN "assignedByPhotoUrl"`,
    );
  }
}
