import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddUserPendingApproval1791400000000 implements MigrationInterface {
  name = 'AddUserPendingApproval1791400000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TYPE "users_status_enum" ADD VALUE IF NOT EXISTS 'pending_approval'`,
    );
  }

  public async down(): Promise<void> {
    // Postgres can't drop an enum value; leaving it unused is harmless.
  }
}
