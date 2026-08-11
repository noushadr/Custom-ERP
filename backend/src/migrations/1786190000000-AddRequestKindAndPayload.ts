import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddRequestKindAndPayload1786190000000
  implements MigrationInterface
{
  name = 'AddRequestKindAndPayload1786190000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "employee_requests_kind_enum" AS ENUM('general', 'profile_change', 'item')`,
    );
    await queryRunner.query(
      `ALTER TABLE "employee_requests" ADD "kind" "employee_requests_kind_enum" NOT NULL DEFAULT 'general'`,
    );
    await queryRunner.query(
      `ALTER TABLE "employee_requests" ADD "payload" jsonb`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "employee_requests" DROP COLUMN "payload"`,
    );
    await queryRunner.query(
      `ALTER TABLE "employee_requests" DROP COLUMN "kind"`,
    );
    await queryRunner.query(`DROP TYPE "employee_requests_kind_enum"`);
  }
}
