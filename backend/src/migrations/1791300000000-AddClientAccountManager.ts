import { MigrationInterface, QueryRunner } from 'typeorm';

/** A client's account manager (the employee who owns the relationship), plus
 * the notification link target used for client-health notifications.
 * Postgres can't drop a single enum value, so `down` leaves it. */
export class AddClientAccountManager1791300000000 implements MigrationInterface {
  name = 'AddClientAccountManager1791300000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "clients" ADD "accountManagerId" uuid`);
    await queryRunner.query(
      `ALTER TABLE "clients" ADD CONSTRAINT "FK_clients_accountManagerId" FOREIGN KEY ("accountManagerId") REFERENCES "employees"("id") ON DELETE SET NULL ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TYPE "notification_link_target_enum" ADD VALUE IF NOT EXISTS 'clients'`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "clients" DROP CONSTRAINT "FK_clients_accountManagerId"`,
    );
    await queryRunner.query(`ALTER TABLE "clients" DROP COLUMN "accountManagerId"`);
  }
}
