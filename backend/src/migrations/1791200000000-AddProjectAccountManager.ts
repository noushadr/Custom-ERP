import { MigrationInterface, QueryRunner } from 'typeorm';

/** A project's owner / account manager — one of its assigned employees. */
export class AddProjectAccountManager1791200000000
  implements MigrationInterface
{
  name = 'AddProjectAccountManager1791200000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "projects" ADD "accountManagerId" uuid`);
    await queryRunner.query(
      `ALTER TABLE "projects" ADD CONSTRAINT "FK_projects_accountManagerId" FOREIGN KEY ("accountManagerId") REFERENCES "employees"("id") ON DELETE SET NULL ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "projects" DROP CONSTRAINT "FK_projects_accountManagerId"`,
    );
    await queryRunner.query(`ALTER TABLE "projects" DROP COLUMN "accountManagerId"`);
  }
}
