import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddKnowledgeBase1786900000000 implements MigrationInterface {
  name = 'AddKnowledgeBase1786900000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "knowledge_base_articles_visibilitytype_enum" AS ENUM('everyone', 'roles', 'departments', 'roles_and_departments')`,
    );
    await queryRunner.query(
      `CREATE TABLE "knowledge_base_articles" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "title" character varying NOT NULL, "content" jsonb NOT NULL, "visibilityType" "knowledge_base_articles_visibilitytype_enum" NOT NULL, "authorUserId" uuid NOT NULL, "authorName" character varying NOT NULL, "lastEditedByUserId" uuid NOT NULL, "lastEditedByName" character varying NOT NULL, "versionNumber" integer NOT NULL DEFAULT 1, "isArchived" boolean NOT NULL DEFAULT false, CONSTRAINT "PK_knowledge_base_articles_id" PRIMARY KEY ("id"))`,
    );

    await queryRunner.query(
      `CREATE TABLE "knowledge_base_article_versions" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "articleId" uuid NOT NULL, "versionNumber" integer NOT NULL, "title" character varying NOT NULL, "content" jsonb NOT NULL, "editorUserId" uuid NOT NULL, "editorName" character varying NOT NULL, CONSTRAINT "PK_knowledge_base_article_versions_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_knowledge_base_article_versions_articleId" ON "knowledge_base_article_versions" ("articleId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "knowledge_base_article_versions" ADD CONSTRAINT "FK_knowledge_base_article_versions_articleId" FOREIGN KEY ("articleId") REFERENCES "knowledge_base_articles"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );

    await queryRunner.query(
      `CREATE TABLE "knowledge_base_article_target_roles" ("articleId" uuid NOT NULL, "roleId" uuid NOT NULL, CONSTRAINT "PK_knowledge_base_article_target_roles" PRIMARY KEY ("articleId", "roleId"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_knowledge_base_article_target_roles_articleId" ON "knowledge_base_article_target_roles" ("articleId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_knowledge_base_article_target_roles_roleId" ON "knowledge_base_article_target_roles" ("roleId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "knowledge_base_article_target_roles" ADD CONSTRAINT "FK_knowledge_base_article_target_roles_articleId" FOREIGN KEY ("articleId") REFERENCES "knowledge_base_articles"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "knowledge_base_article_target_roles" ADD CONSTRAINT "FK_knowledge_base_article_target_roles_roleId" FOREIGN KEY ("roleId") REFERENCES "roles"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );

    await queryRunner.query(
      `CREATE TABLE "knowledge_base_article_target_departments" ("articleId" uuid NOT NULL, "departmentId" uuid NOT NULL, CONSTRAINT "PK_knowledge_base_article_target_departments" PRIMARY KEY ("articleId", "departmentId"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_knowledge_base_article_target_departments_articleId" ON "knowledge_base_article_target_departments" ("articleId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_knowledge_base_article_target_departments_departmentId" ON "knowledge_base_article_target_departments" ("departmentId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "knowledge_base_article_target_departments" ADD CONSTRAINT "FK_knowledge_base_article_target_departments_articleId" FOREIGN KEY ("articleId") REFERENCES "knowledge_base_articles"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "knowledge_base_article_target_departments" ADD CONSTRAINT "FK_knowledge_base_article_target_departments_departmentId" FOREIGN KEY ("departmentId") REFERENCES "departments"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "knowledge_base_article_target_departments" DROP CONSTRAINT "FK_knowledge_base_article_target_departments_departmentId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "knowledge_base_article_target_departments" DROP CONSTRAINT "FK_knowledge_base_article_target_departments_articleId"`,
    );
    await queryRunner.query(
      `DROP INDEX "IDX_knowledge_base_article_target_departments_departmentId"`,
    );
    await queryRunner.query(
      `DROP INDEX "IDX_knowledge_base_article_target_departments_articleId"`,
    );
    await queryRunner.query(
      `DROP TABLE "knowledge_base_article_target_departments"`,
    );

    await queryRunner.query(
      `ALTER TABLE "knowledge_base_article_target_roles" DROP CONSTRAINT "FK_knowledge_base_article_target_roles_roleId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "knowledge_base_article_target_roles" DROP CONSTRAINT "FK_knowledge_base_article_target_roles_articleId"`,
    );
    await queryRunner.query(
      `DROP INDEX "IDX_knowledge_base_article_target_roles_roleId"`,
    );
    await queryRunner.query(
      `DROP INDEX "IDX_knowledge_base_article_target_roles_articleId"`,
    );
    await queryRunner.query(`DROP TABLE "knowledge_base_article_target_roles"`);

    await queryRunner.query(
      `ALTER TABLE "knowledge_base_article_versions" DROP CONSTRAINT "FK_knowledge_base_article_versions_articleId"`,
    );
    await queryRunner.query(
      `DROP INDEX "IDX_knowledge_base_article_versions_articleId"`,
    );
    await queryRunner.query(`DROP TABLE "knowledge_base_article_versions"`);

    await queryRunner.query(`DROP TABLE "knowledge_base_articles"`);
    await queryRunner.query(
      `DROP TYPE "knowledge_base_articles_visibilitytype_enum"`,
    );
  }
}
