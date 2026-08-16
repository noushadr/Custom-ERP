import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddTeamIsArchived1786400000000 implements MigrationInterface {
  name = 'AddTeamIsArchived1786400000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "teams" ADD "isArchived" boolean NOT NULL DEFAULT false`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "teams" DROP COLUMN "isArchived"`);
  }
}
