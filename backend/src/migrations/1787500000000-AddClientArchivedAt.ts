import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddClientArchivedAt1787500000000 implements MigrationInterface {
  name = 'AddClientArchivedAt1787500000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "clients" ADD "archivedAt" TIMESTAMP WITH TIME ZONE`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "clients" DROP COLUMN "archivedAt"`);
  }
}
