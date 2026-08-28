import { MigrationInterface, QueryRunner } from 'typeorm';

/** Adds a free-text lead-source field to Client (e.g. "Whatsapp", "Call",
 * "Form", "Email") for importing real sales/deal-tracking data. */
export class AddClientLeadSource1788800000000 implements MigrationInterface {
  name = 'AddClientLeadSource1788800000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "clients" ADD "leadSource" character varying`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "clients" DROP COLUMN "leadSource"`);
  }
}
