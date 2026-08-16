import { MigrationInterface, QueryRunner } from 'typeorm';

export class RemoveTeams1786600000000 implements MigrationInterface {
  name = 'RemoveTeams1786600000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // IF EXISTS throughout: in local dev, TypeORM's synchronize (enabled
    // outside production) may have already dropped the FK/column ahead of
    // this migration running — this stays correct either way, including
    // against a production database that never had synchronize touch it.
    await queryRunner.query(
      `ALTER TABLE "employees" DROP CONSTRAINT IF EXISTS "FK_66f8bf74042e2f42ded42fecf70"`,
    );
    await queryRunner.query(
      `ALTER TABLE "employees" DROP COLUMN IF EXISTS "teamId"`,
    );
    await queryRunner.query(`DROP TABLE IF EXISTS "teams"`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "teams" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "name" character varying NOT NULL, "departmentId" uuid NOT NULL, "leadEmployeeId" character varying, "isArchived" boolean NOT NULL DEFAULT false, CONSTRAINT "PK_7e5523774a38b08a6236d322403" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `ALTER TABLE "teams" ADD CONSTRAINT "FK_ece1d9122a8f3334815ddba096e" FOREIGN KEY ("departmentId") REFERENCES "departments"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "employees" ADD "teamId" uuid`,
    );
    await queryRunner.query(
      `ALTER TABLE "employees" ADD CONSTRAINT "FK_66f8bf74042e2f42ded42fecf70" FOREIGN KEY ("teamId") REFERENCES "teams"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }
}
