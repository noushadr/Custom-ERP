import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddAssets1786300000000 implements MigrationInterface {
  name = 'AddAssets1786300000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "assets_status_enum" AS ENUM('available', 'assigned', 'repair', 'lost', 'retired')`,
    );
    await queryRunner.query(
      `CREATE TABLE "assets" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "name" character varying NOT NULL, "category" character varying, "serialNumber" character varying, "status" "assets_status_enum" NOT NULL DEFAULT 'available', "assignedEmployeeId" uuid, "assignedAt" TIMESTAMP WITH TIME ZONE, "notes" text, CONSTRAINT "PK_assets_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_assets_assignedEmployeeId" ON "assets" ("assignedEmployeeId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_assets_status" ON "assets" ("status")`,
    );
    await queryRunner.query(
      `ALTER TABLE "assets" ADD CONSTRAINT "FK_assets_assignedEmployeeId" FOREIGN KEY ("assignedEmployeeId") REFERENCES "employees"("id") ON DELETE SET NULL ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "assets" DROP CONSTRAINT "FK_assets_assignedEmployeeId"`,
    );
    await queryRunner.query(`DROP INDEX "IDX_assets_status"`);
    await queryRunner.query(`DROP INDEX "IDX_assets_assignedEmployeeId"`);
    await queryRunner.query(`DROP TABLE "assets"`);
    await queryRunner.query(`DROP TYPE "assets_status_enum"`);
  }
}
