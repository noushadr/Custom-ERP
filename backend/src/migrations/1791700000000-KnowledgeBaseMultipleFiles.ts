import { MigrationInterface, QueryRunner } from 'typeorm';

/** A file article can now carry up to three files. The single-file columns
 * become one `files` jsonb list (backfilled, so existing SOPs keep their
 * file) on both articles and their versions. */
export class KnowledgeBaseMultipleFiles1791700000000
  implements MigrationInterface
{
  name = 'KnowledgeBaseMultipleFiles1791700000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    for (const table of [
      'knowledge_base_articles',
      'knowledge_base_article_versions',
    ]) {
      await queryRunner.query(
        `ALTER TABLE "${table}" ADD COLUMN "files" jsonb NOT NULL DEFAULT '[]'::jsonb`,
      );
      await queryRunner.query(
        `UPDATE "${table}" SET "files" = jsonb_build_array(jsonb_build_object('fileName', "fileName", 'storedFileName', "storedFileName", 'mimeType', "fileMimeType", 'sizeBytes', "fileSizeBytes")) WHERE "storedFileName" IS NOT NULL`,
      );
      await queryRunner.query(`ALTER TABLE "${table}" DROP COLUMN "fileName"`);
      await queryRunner.query(
        `ALTER TABLE "${table}" DROP COLUMN "storedFileName"`,
      );
      await queryRunner.query(
        `ALTER TABLE "${table}" DROP COLUMN "fileMimeType"`,
      );
      await queryRunner.query(
        `ALTER TABLE "${table}" DROP COLUMN "fileSizeBytes"`,
      );
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    for (const table of [
      'knowledge_base_articles',
      'knowledge_base_article_versions',
    ]) {
      await queryRunner.query(
        `ALTER TABLE "${table}" ADD COLUMN "fileName" character varying, ADD COLUMN "storedFileName" character varying, ADD COLUMN "fileMimeType" character varying, ADD COLUMN "fileSizeBytes" integer`,
      );
      await queryRunner.query(
        `UPDATE "${table}" SET "fileName" = "files"->0->>'fileName', "storedFileName" = "files"->0->>'storedFileName', "fileMimeType" = "files"->0->>'mimeType', "fileSizeBytes" = ("files"->0->>'sizeBytes')::integer WHERE jsonb_array_length("files") > 0`,
      );
      await queryRunner.query(`ALTER TABLE "${table}" DROP COLUMN "files"`);
    }
  }
}
