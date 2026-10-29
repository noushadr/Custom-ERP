import { MigrationInterface, QueryRunner } from 'typeorm';

/** Reshapes performance reviews to match the company's mid-year evaluation
 * form: grouped criteria with per-rating comments, an overall performance
 * rating. The old sample
 * criteria are replaced by the form's real ones (every existing review was
 * already cleared by `ClearPerformanceReviewsForDecemberCycle`). */
export class PerformanceReviewEvaluationForm1791000000000
  implements MigrationInterface
{
  name = 'PerformanceReviewEvaluationForm1791000000000';

  private static readonly rated: [string, string][] = [
    ['Performance Overview', 'Quality of Work'],
    ['Performance Overview', 'Productivity & Efficiency'],
    ['Performance Overview', 'Meeting Deadlines'],
    ['Performance Overview', 'Job Knowledge & Skills'],
    ['Performance Overview', 'Attention to Detail'],
    ['Performance Overview', 'Client Dealing'],
    ['Behavioral & Professional Competencies', 'Communication Skills'],
    ['Behavioral & Professional Competencies', 'Teamwork & Collaboration'],
    ['Behavioral & Professional Competencies', 'Initiative & Ownership'],
    ['Behavioral & Professional Competencies', 'Adaptability & Flexibility'],
    ['Behavioral & Professional Competencies', 'Professional Conduct'],
  ];

  private static readonly text = [
    'Strengths',
    'Areas for Improvement',
    'Goals & Development Plan',
    'Compensation / Role Review',
  ];

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "performance_reviews_overallrating_enum" AS ENUM('needs_improvement', 'meets_expectations', 'exceeds_expectations', 'outstanding')`,
    );
    await queryRunner.query(
      `ALTER TABLE "performance_reviews" ADD "overallRating" "performance_reviews_overallrating_enum"`,
    );
    await queryRunner.query(
      `ALTER TABLE "performance_review_criteria" ADD "section" character varying, ADD "hasComment" boolean NOT NULL DEFAULT false`,
    );
    await queryRunner.query(
      `ALTER TABLE "performance_review_responses" ADD "section" character varying, ADD "hasComment" boolean NOT NULL DEFAULT false, ADD "commentValue" text`,
    );

    await queryRunner.query(`DELETE FROM "performance_review_criteria"`);
    let order = 0;
    for (const [section, name] of PerformanceReviewEvaluationForm1791000000000.rated) {
      await queryRunner.query(
        `INSERT INTO "performance_review_criteria" ("id", "name", "responseType", "sortOrder", "section", "hasComment") VALUES (gen_random_uuid(), $1, 'rating', $2, $3, true)`,
        [name, order++, section],
      );
    }
    for (const name of PerformanceReviewEvaluationForm1791000000000.text) {
      await queryRunner.query(
        `INSERT INTO "performance_review_criteria" ("id", "name", "responseType", "sortOrder") VALUES (gen_random_uuid(), $1, 'text', $2)`,
        [name, order++],
      );
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "performance_review_responses" DROP COLUMN "commentValue", DROP COLUMN "hasComment", DROP COLUMN "section"`,
    );
    await queryRunner.query(
      `ALTER TABLE "performance_review_criteria" DROP COLUMN "hasComment", DROP COLUMN "section"`,
    );
    await queryRunner.query(
      `ALTER TABLE "performance_reviews" DROP COLUMN "overallRating"`,
    );
    await queryRunner.query(`DROP TYPE "performance_reviews_overallrating_enum"`);
  }
}
