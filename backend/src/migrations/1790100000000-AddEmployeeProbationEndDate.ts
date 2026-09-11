import { MigrationInterface, QueryRunner } from 'typeorm';

/** Every employee goes through probation, but not for a fixed company-wide
 * duration — this stores the actual per-employee end date (defaulted to 3
 * months from joiningDate when the employee is added, freely editable afterward).
 * Whether someone is currently "on probation" is computed on every read
 * from this against today's date, never stored. */
export class AddEmployeeProbationEndDate1790100000000
  implements MigrationInterface
{
  name = 'AddEmployeeProbationEndDate1790100000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "employees" ADD "probationEndDate" date`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "employees" DROP COLUMN "probationEndDate"`,
    );
  }
}
