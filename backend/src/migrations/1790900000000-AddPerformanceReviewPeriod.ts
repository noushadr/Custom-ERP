import { MigrationInterface, QueryRunner } from 'typeorm';

/** Reviews now run twice a year (June = 1, December = 2), so uniqueness is
 * per (employeeId, reviewYear, reviewPeriod). Existing rows are December
 * cycle (2), the column default. */
export class AddPerformanceReviewPeriod1790900000000
  implements MigrationInterface
{
  name = 'AddPerformanceReviewPeriod1790900000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "performance_reviews" ADD "reviewPeriod" smallint NOT NULL DEFAULT 2`,
    );
    await queryRunner.query(
      `DROP INDEX "IDX_performance_reviews_employeeId_reviewYear"`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "IDX_performance_reviews_employeeId_reviewYear_reviewPeriod" ON "performance_reviews" ("employeeId", "reviewYear", "reviewPeriod")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX "IDX_performance_reviews_employeeId_reviewYear_reviewPeriod"`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "IDX_performance_reviews_employeeId_reviewYear" ON "performance_reviews" ("employeeId", "reviewYear")`,
    );
    await queryRunner.query(
      `ALTER TABLE "performance_reviews" DROP COLUMN "reviewPeriod"`,
    );
  }
}
