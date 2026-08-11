import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddDepartmentIsArchived1786185000000 implements MigrationInterface {
  name = 'AddDepartmentIsArchived1786185000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "departments" ADD "isArchived" boolean NOT NULL DEFAULT false`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "departments" DROP COLUMN "isArchived"`,
    );
  }
}
