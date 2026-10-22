import { MigrationInterface, QueryRunner } from 'typeorm';

/** Lets a Knowledge Base article be an uploaded file instead of written
 * text. `contentKind` is NOT NULL but has a default, so every existing
 * article safely becomes 'rich_text'; the file columns are nullable (only
 * set for uploaded-file articles and their versions). */
export class AddKnowledgeBaseFileArticles1790600000000
  implements MigrationInterface
{
  name = 'AddKnowledgeBaseFileArticles1790600000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "knowledge_base_content_kind_enum" AS ENUM ('rich_text', 'file')`,
    );
    await queryRunner.query(
      `ALTER TABLE "knowledge_base_articles"
         ADD "contentKind" "knowledge_base_content_kind_enum" NOT NULL DEFAULT 'rich_text',
         ADD "fileName" character varying,
         ADD "storedFileName" character varying,
         ADD "fileMimeType" character varying,
         ADD "fileSizeBytes" integer`,
    );
    await queryRunner.query(
      `ALTER TABLE "knowledge_base_article_versions"
         ADD "fileName" character varying,
         ADD "storedFileName" character varying,
         ADD "fileMimeType" character varying,
         ADD "fileSizeBytes" integer`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "knowledge_base_article_versions"
         DROP COLUMN "fileSizeBytes",
         DROP COLUMN "fileMimeType",
         DROP COLUMN "storedFileName",
         DROP COLUMN "fileName"`,
    );
    await queryRunner.query(
      `ALTER TABLE "knowledge_base_articles"
         DROP COLUMN "fileSizeBytes",
         DROP COLUMN "fileMimeType",
         DROP COLUMN "storedFileName",
         DROP COLUMN "fileName",
         DROP COLUMN "contentKind"`,
    );
    await queryRunner.query(`DROP TYPE "knowledge_base_content_kind_enum"`);
  }
}
