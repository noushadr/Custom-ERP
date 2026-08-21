import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddClientHealth1787400000000 implements MigrationInterface {
  name = 'AddClientHealth1787400000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "client_health_status_enum" AS ENUM('healthy', 'attention_required', 'at_risk')`,
    );
    await queryRunner.query(
      `ALTER TABLE "clients" ADD "healthStatus" "client_health_status_enum" NOT NULL DEFAULT 'healthy'`,
    );
    await queryRunner.query(
      `ALTER TABLE "clients" ADD "healthFactors" text array NOT NULL DEFAULT '{}'`,
    );
    await queryRunner.query(`ALTER TABLE "clients" ADD "healthNotes" text`);

    await queryRunner.query(
      `CREATE TABLE "client_health_history" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "clientId" uuid NOT NULL, "previousStatus" "client_health_status_enum" NOT NULL, "newStatus" "client_health_status_enum" NOT NULL, "factors" text array NOT NULL DEFAULT '{}', "notes" text, "actorUserId" uuid NOT NULL, "actorName" character varying NOT NULL, CONSTRAINT "PK_client_health_history_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_client_health_history_clientId" ON "client_health_history" ("clientId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "client_health_history" ADD CONSTRAINT "FK_client_health_history_clientId" FOREIGN KEY ("clientId") REFERENCES "clients"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "client_health_history" DROP CONSTRAINT "FK_client_health_history_clientId"`,
    );
    await queryRunner.query(`DROP INDEX "IDX_client_health_history_clientId"`);
    await queryRunner.query(`DROP TABLE "client_health_history"`);

    await queryRunner.query(`ALTER TABLE "clients" DROP COLUMN "healthNotes"`);
    await queryRunner.query(
      `ALTER TABLE "clients" DROP COLUMN "healthFactors"`,
    );
    await queryRunner.query(
      `ALTER TABLE "clients" DROP COLUMN "healthStatus"`,
    );
    await queryRunner.query(`DROP TYPE "client_health_status_enum"`);
  }
}
