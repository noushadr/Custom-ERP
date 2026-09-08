import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddEmployeeOfMonthNomination1789900000000
  implements MigrationInterface
{
  name = 'AddEmployeeOfMonthNomination1789900000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TYPE "employee_requests_kind_enum" ADD VALUE 'employee_of_month_nomination'`,
    );
    await queryRunner.query(
      `ALTER TABLE "employee_requests" ADD "nomineeEmployeeId" uuid`,
    );
    await queryRunner.query(
      `ALTER TABLE "employee_requests" ADD CONSTRAINT "FK_employee_requests_nominee" FOREIGN KEY ("nomineeEmployeeId") REFERENCES "employees"("id")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "employee_requests" DROP CONSTRAINT "FK_employee_requests_nominee"`,
    );
    await queryRunner.query(
      `ALTER TABLE "employee_requests" DROP COLUMN "nomineeEmployeeId"`,
    );
    // Postgres has no ALTER TYPE ... DROP VALUE — the enum label is left in
    // place on rollback, matching the precedent set by every other
    // Add*NotificationLinkTarget migration's own down() in this codebase.
  }
}
