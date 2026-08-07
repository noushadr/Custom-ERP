import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddNotices1786105000000 implements MigrationInterface {
  name = 'AddNotices1786105000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "notices" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "title" character varying NOT NULL, "body" text NOT NULL, "authorUserId" character varying NOT NULL, "authorName" character varying NOT NULL, CONSTRAINT "PK_notices_id" PRIMARY KEY ("id"))`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "notices"`);
  }
}
