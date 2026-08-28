import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddLeads1788900000000 implements MigrationInterface {
  name = 'AddLeads1788900000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "leads" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "leadDate" date NOT NULL, "fullName" character varying NOT NULL, "companyName" character varying, "leadSource" character varying, "phone" character varying, "email" character varying, "country" character varying, "remarks" text, "serviceInterested" character varying, "isArchived" boolean NOT NULL DEFAULT false, CONSTRAINT "PK_leads_id" PRIMARY KEY ("id"))`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "leads"`);
  }
}
