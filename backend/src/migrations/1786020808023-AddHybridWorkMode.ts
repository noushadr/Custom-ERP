import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddHybridWorkMode1786020808023 implements MigrationInterface {
  name = 'AddHybridWorkMode1786020808023';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TYPE "employees_workmode_enum" ADD VALUE IF NOT EXISTS 'hybrid'`,
    );
  }

  public async down(): Promise<void> {
    // Postgres has no direct "remove enum value" operation — reverting would
    // require recreating the type and is not needed for this additive change.
  }
}
