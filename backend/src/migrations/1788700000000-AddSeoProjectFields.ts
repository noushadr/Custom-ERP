import { MigrationInterface, QueryRunner } from 'typeorm';

/** Adds free-text SEO-engagement fields for importing real client/project
 * data — a client's country, and a project's package tier, backlink
 * target, external sheet/folder labels, and reference-only (no password)
 * working-email/Ahrefs account fields. */
export class AddSeoProjectFields1788700000000 implements MigrationInterface {
  name = 'AddSeoProjectFields1788700000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "clients" ADD "country" character varying`,
    );
    await queryRunner.query(
      `ALTER TABLE "projects" ADD "packageName" character varying`,
    );
    await queryRunner.query(
      `ALTER TABLE "projects" ADD "backlinksTarget" character varying`,
    );
    await queryRunner.query(
      `ALTER TABLE "projects" ADD "seoSheetName" character varying`,
    );
    await queryRunner.query(
      `ALTER TABLE "projects" ADD "projectFolderName" character varying`,
    );
    await queryRunner.query(
      `ALTER TABLE "projects" ADD "workingEmailAccount" character varying`,
    );
    await queryRunner.query(
      `ALTER TABLE "projects" ADD "ahrefsAccount" character varying`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "projects" DROP COLUMN "ahrefsAccount"`,
    );
    await queryRunner.query(
      `ALTER TABLE "projects" DROP COLUMN "workingEmailAccount"`,
    );
    await queryRunner.query(
      `ALTER TABLE "projects" DROP COLUMN "projectFolderName"`,
    );
    await queryRunner.query(
      `ALTER TABLE "projects" DROP COLUMN "seoSheetName"`,
    );
    await queryRunner.query(
      `ALTER TABLE "projects" DROP COLUMN "backlinksTarget"`,
    );
    await queryRunner.query(`ALTER TABLE "projects" DROP COLUMN "packageName"`);
    await queryRunner.query(`ALTER TABLE "clients" DROP COLUMN "country"`);
  }
}
