import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddPerformanceReviews1786800000000 implements MigrationInterface {
  name = 'AddPerformanceReviews1786800000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "performance_review_criteria_responsetype_enum" AS ENUM('rating', 'text')`,
    );
    await queryRunner.query(
      `CREATE TABLE "performance_review_criteria" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "name" character varying NOT NULL, "responseType" "performance_review_criteria_responsetype_enum" NOT NULL, "sortOrder" integer NOT NULL, "isArchived" boolean NOT NULL DEFAULT false, CONSTRAINT "PK_performance_review_criteria_id" PRIMARY KEY ("id"))`,
    );

    await queryRunner.query(
      `CREATE TYPE "performance_reviews_status_enum" AS ENUM('pending', 'completed', 'finalized')`,
    );
    await queryRunner.query(
      `CREATE TABLE "performance_reviews" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "employeeId" uuid NOT NULL, "reviewYear" integer NOT NULL, "dueDate" date NOT NULL, "status" "performance_reviews_status_enum" NOT NULL DEFAULT 'pending', "employeeComments" text, "completedByUserId" uuid, "completedByName" character varying, "completedAt" TIMESTAMP WITH TIME ZONE, "completedAsManager" boolean, "finalizedByUserId" uuid, "finalizedByName" character varying, "finalizedAt" TIMESTAMP WITH TIME ZONE, CONSTRAINT "PK_performance_reviews_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "IDX_performance_reviews_employeeId_reviewYear" ON "performance_reviews" ("employeeId", "reviewYear")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_performance_reviews_status" ON "performance_reviews" ("status")`,
    );
    await queryRunner.query(
      `ALTER TABLE "performance_reviews" ADD CONSTRAINT "FK_performance_reviews_employeeId" FOREIGN KEY ("employeeId") REFERENCES "employees"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );

    await queryRunner.query(
      `CREATE TYPE "performance_review_responses_responsetype_enum" AS ENUM('rating', 'text')`,
    );
    await queryRunner.query(
      `CREATE TABLE "performance_review_responses" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "performanceReviewId" uuid NOT NULL, "criterionId" uuid, "criterionName" character varying NOT NULL, "responseType" "performance_review_responses_responsetype_enum" NOT NULL, "sortOrder" integer NOT NULL, "ratingValue" integer, "textValue" text, CONSTRAINT "PK_performance_review_responses_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_performance_review_responses_performanceReviewId" ON "performance_review_responses" ("performanceReviewId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "performance_review_responses" ADD CONSTRAINT "FK_performance_review_responses_performanceReviewId" FOREIGN KEY ("performanceReviewId") REFERENCES "performance_reviews"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "performance_review_responses" ADD CONSTRAINT "FK_performance_review_responses_criterionId" FOREIGN KEY ("criterionId") REFERENCES "performance_review_criteria"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "performance_review_responses" DROP CONSTRAINT "FK_performance_review_responses_criterionId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "performance_review_responses" DROP CONSTRAINT "FK_performance_review_responses_performanceReviewId"`,
    );
    await queryRunner.query(
      `DROP INDEX "IDX_performance_review_responses_performanceReviewId"`,
    );
    await queryRunner.query(`DROP TABLE "performance_review_responses"`);
    await queryRunner.query(
      `DROP TYPE "performance_review_responses_responsetype_enum"`,
    );

    await queryRunner.query(
      `ALTER TABLE "performance_reviews" DROP CONSTRAINT "FK_performance_reviews_employeeId"`,
    );
    await queryRunner.query(`DROP INDEX "IDX_performance_reviews_status"`);
    await queryRunner.query(
      `DROP INDEX "IDX_performance_reviews_employeeId_reviewYear"`,
    );
    await queryRunner.query(`DROP TABLE "performance_reviews"`);
    await queryRunner.query(`DROP TYPE "performance_reviews_status_enum"`);

    await queryRunner.query(`DROP TABLE "performance_review_criteria"`);
    await queryRunner.query(
      `DROP TYPE "performance_review_criteria_responsetype_enum"`,
    );
  }
}
