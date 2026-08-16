import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddHolidays1786500000000 implements MigrationInterface {
  name = 'AddHolidays1786500000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "holidays" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "name" character varying NOT NULL, "date" date NOT NULL, CONSTRAINT "PK_holidays_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_holidays_date" ON "holidays" ("date")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "IDX_holidays_date"`);
    await queryRunner.query(`DROP TABLE "holidays"`);
  }
}
