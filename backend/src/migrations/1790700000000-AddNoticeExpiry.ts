import { MigrationInterface, QueryRunner } from 'typeorm';

/** Lets a company notice have an end date. Nullable: every notice that
 * already exists keeps `expiresAt = NULL`, i.e. it stays visible forever
 * exactly as before. */
export class AddNoticeExpiry1790700000000 implements MigrationInterface {
  name = 'AddNoticeExpiry1790700000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "notices" ADD "expiresAt" TIMESTAMP WITH TIME ZONE`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "notices" DROP COLUMN "expiresAt"`);
  }
}
