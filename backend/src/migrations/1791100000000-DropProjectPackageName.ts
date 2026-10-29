import { MigrationInterface, QueryRunner } from 'typeorm';

/** Projects no longer carry a free-text "package" tier. */
export class DropProjectPackageName1791100000000 implements MigrationInterface {
  name = 'DropProjectPackageName1791100000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "projects" DROP COLUMN IF EXISTS "packageName"`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "projects" ADD "packageName" character varying`,
    );
  }
}
