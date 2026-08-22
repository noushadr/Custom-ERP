import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddChecklists1786700000000 implements MigrationInterface {
  name = 'AddChecklists1786700000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "checklist_template_items_type_enum" AS ENUM('onboarding', 'offboarding')`,
    );
    await queryRunner.query(
      `CREATE TYPE "checklist_template_items_appliestoworkmode_enum" AS ENUM('on_site', 'remote', 'hybrid')`,
    );
    await queryRunner.query(
      `CREATE TABLE "checklist_template_items" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "type" "checklist_template_items_type_enum" NOT NULL, "title" character varying NOT NULL, "description" character varying, "sortOrder" integer NOT NULL, "appliesToWorkMode" "checklist_template_items_appliestoworkmode_enum", "isArchived" boolean NOT NULL DEFAULT false, CONSTRAINT "PK_checklist_template_items_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_checklist_template_items_type" ON "checklist_template_items" ("type")`,
    );

    await queryRunner.query(
      `CREATE TYPE "employee_checklist_items_type_enum" AS ENUM('onboarding', 'offboarding')`,
    );
    await queryRunner.query(
      `CREATE TABLE "employee_checklist_items" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "employeeId" uuid NOT NULL, "templateItemId" uuid, "type" "employee_checklist_items_type_enum" NOT NULL, "title" character varying NOT NULL, "sortOrder" integer NOT NULL, "isCompleted" boolean NOT NULL DEFAULT false, "completedAt" TIMESTAMP WITH TIME ZONE, "completedByUserId" uuid, "completedByName" character varying, "note" character varying, CONSTRAINT "PK_employee_checklist_items_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_employee_checklist_items_employeeId_type" ON "employee_checklist_items" ("employeeId", "type")`,
    );
    await queryRunner.query(
      `ALTER TABLE "employee_checklist_items" ADD CONSTRAINT "FK_employee_checklist_items_employeeId" FOREIGN KEY ("employeeId") REFERENCES "employees"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "employee_checklist_items" ADD CONSTRAINT "FK_employee_checklist_items_templateItemId" FOREIGN KEY ("templateItemId") REFERENCES "checklist_template_items"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "employee_checklist_items" DROP CONSTRAINT "FK_employee_checklist_items_templateItemId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "employee_checklist_items" DROP CONSTRAINT "FK_employee_checklist_items_employeeId"`,
    );
    await queryRunner.query(
      `DROP INDEX "IDX_employee_checklist_items_employeeId_type"`,
    );
    await queryRunner.query(`DROP TABLE "employee_checklist_items"`);
    await queryRunner.query(`DROP TYPE "employee_checklist_items_type_enum"`);

    await queryRunner.query(`DROP INDEX "IDX_checklist_template_items_type"`);
    await queryRunner.query(`DROP TABLE "checklist_template_items"`);
    await queryRunner.query(
      `DROP TYPE "checklist_template_items_appliestoworkmode_enum"`,
    );
    await queryRunner.query(`DROP TYPE "checklist_template_items_type_enum"`);
  }
}
