import { MigrationInterface, QueryRunner } from 'typeorm';

/** Same two-column shape as `Client.isArchived`/`archivedAt` — independent
 * of `status`, so archiving a project never implies (or is implied by) it
 * being Completed/Cancelled. */
export class AddProjectArchive1790200000000 implements MigrationInterface {
  name = 'AddProjectArchive1790200000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "projects" ADD "isArchived" boolean NOT NULL DEFAULT false`,
    );
    await queryRunner.query(
      `ALTER TABLE "projects" ADD "archivedAt" TIMESTAMP WITH TIME ZONE`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "projects" DROP COLUMN "archivedAt"`);
    await queryRunner.query(`ALTER TABLE "projects" DROP COLUMN "isArchived"`);
  }
}
