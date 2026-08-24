import { MigrationInterface, QueryRunner } from 'typeorm';

export class RemoveLeadArchiving1789000000000 implements MigrationInterface {
  name = 'RemoveLeadArchiving1789000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "leads" DROP COLUMN "isArchived"`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "leads" ADD "isArchived" boolean NOT NULL DEFAULT false`,
    );
  }
}
