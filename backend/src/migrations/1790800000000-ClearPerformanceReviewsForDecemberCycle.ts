import { MigrationInterface, QueryRunner } from 'typeorm';

/** Performance reviews became an annual December cycle (auto-created for
 * everyone on 1 December, `reviewYear` = calendar year). The old
 * anniversary-based reviews use a different meaning of `reviewYear` (years
 * of service), so they are cleared out; responses go with them via the
 * ON DELETE CASCADE foreign key. Irreversible by design. */
export class ClearPerformanceReviewsForDecemberCycle1790800000000
  implements MigrationInterface
{
  name = 'ClearPerformanceReviewsForDecemberCycle1790800000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DELETE FROM "performance_reviews"`);
  }

  public async down(): Promise<void> {
    // Deleted rows cannot be restored.
  }
}
