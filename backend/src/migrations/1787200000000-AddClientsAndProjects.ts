import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddClientsAndProjects1787200000000
  implements MigrationInterface
{
  name = 'AddClientsAndProjects1787200000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "clients" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "companyName" character varying NOT NULL, "industry" character varying, "website" character varying, "address" character varying, "primaryContactName" character varying, "primaryContactEmail" character varying, "primaryContactPhone" character varying, "notes" text, "isArchived" boolean NOT NULL DEFAULT false, CONSTRAINT "PK_clients_id" PRIMARY KEY ("id"))`,
    );

    await queryRunner.query(
      `CREATE TABLE "services" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "name" character varying NOT NULL, "description" character varying, "isArchived" boolean NOT NULL DEFAULT false, CONSTRAINT "UQ_services_name" UNIQUE ("name"), CONSTRAINT "PK_services_id" PRIMARY KEY ("id"))`,
    );

    await queryRunner.query(
      `CREATE TYPE "projects_type_enum" AS ENUM('one_time', 'retainer')`,
    );
    await queryRunner.query(
      `CREATE TYPE "projects_status_enum" AS ENUM('active', 'on_hold', 'completed', 'cancelled')`,
    );
    await queryRunner.query(
      `CREATE TABLE "projects" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "clientId" uuid NOT NULL, "name" character varying NOT NULL, "type" "projects_type_enum" NOT NULL, "status" "projects_status_enum" NOT NULL DEFAULT 'active', "startDate" date NOT NULL, "endDate" date, "renewalDate" date, "originalClientPrice" numeric(12,2) NOT NULL, "deductionRate" numeric(5,2) NOT NULL DEFAULT '20.00', "cost" numeric(12,2) NOT NULL DEFAULT '0.00', "notes" text, CONSTRAINT "PK_projects_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_projects_clientId" ON "projects" ("clientId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "projects" ADD CONSTRAINT "FK_projects_clientId" FOREIGN KEY ("clientId") REFERENCES "clients"("id") ON DELETE RESTRICT ON UPDATE NO ACTION`,
    );

    await queryRunner.query(
      `CREATE TABLE "project_assigned_employees" ("projectId" uuid NOT NULL, "employeeId" uuid NOT NULL, CONSTRAINT "PK_project_assigned_employees" PRIMARY KEY ("projectId", "employeeId"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_project_assigned_employees_projectId" ON "project_assigned_employees" ("projectId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_project_assigned_employees_employeeId" ON "project_assigned_employees" ("employeeId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "project_assigned_employees" ADD CONSTRAINT "FK_project_assigned_employees_projectId" FOREIGN KEY ("projectId") REFERENCES "projects"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "project_assigned_employees" ADD CONSTRAINT "FK_project_assigned_employees_employeeId" FOREIGN KEY ("employeeId") REFERENCES "employees"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );

    await queryRunner.query(
      `CREATE TABLE "project_target_departments" ("projectId" uuid NOT NULL, "departmentId" uuid NOT NULL, CONSTRAINT "PK_project_target_departments" PRIMARY KEY ("projectId", "departmentId"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_project_target_departments_projectId" ON "project_target_departments" ("projectId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_project_target_departments_departmentId" ON "project_target_departments" ("departmentId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "project_target_departments" ADD CONSTRAINT "FK_project_target_departments_projectId" FOREIGN KEY ("projectId") REFERENCES "projects"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "project_target_departments" ADD CONSTRAINT "FK_project_target_departments_departmentId" FOREIGN KEY ("departmentId") REFERENCES "departments"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );

    await queryRunner.query(
      `CREATE TABLE "project_services" ("projectId" uuid NOT NULL, "serviceId" uuid NOT NULL, CONSTRAINT "PK_project_services" PRIMARY KEY ("projectId", "serviceId"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_project_services_projectId" ON "project_services" ("projectId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_project_services_serviceId" ON "project_services" ("serviceId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "project_services" ADD CONSTRAINT "FK_project_services_projectId" FOREIGN KEY ("projectId") REFERENCES "projects"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "project_services" ADD CONSTRAINT "FK_project_services_serviceId" FOREIGN KEY ("serviceId") REFERENCES "services"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "project_services" DROP CONSTRAINT "FK_project_services_serviceId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "project_services" DROP CONSTRAINT "FK_project_services_projectId"`,
    );
    await queryRunner.query(`DROP INDEX "IDX_project_services_serviceId"`);
    await queryRunner.query(`DROP INDEX "IDX_project_services_projectId"`);
    await queryRunner.query(`DROP TABLE "project_services"`);

    await queryRunner.query(
      `ALTER TABLE "project_target_departments" DROP CONSTRAINT "FK_project_target_departments_departmentId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "project_target_departments" DROP CONSTRAINT "FK_project_target_departments_projectId"`,
    );
    await queryRunner.query(
      `DROP INDEX "IDX_project_target_departments_departmentId"`,
    );
    await queryRunner.query(
      `DROP INDEX "IDX_project_target_departments_projectId"`,
    );
    await queryRunner.query(`DROP TABLE "project_target_departments"`);

    await queryRunner.query(
      `ALTER TABLE "project_assigned_employees" DROP CONSTRAINT "FK_project_assigned_employees_employeeId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "project_assigned_employees" DROP CONSTRAINT "FK_project_assigned_employees_projectId"`,
    );
    await queryRunner.query(
      `DROP INDEX "IDX_project_assigned_employees_employeeId"`,
    );
    await queryRunner.query(
      `DROP INDEX "IDX_project_assigned_employees_projectId"`,
    );
    await queryRunner.query(`DROP TABLE "project_assigned_employees"`);

    await queryRunner.query(
      `ALTER TABLE "projects" DROP CONSTRAINT "FK_projects_clientId"`,
    );
    await queryRunner.query(`DROP INDEX "IDX_projects_clientId"`);
    await queryRunner.query(`DROP TABLE "projects"`);
    await queryRunner.query(`DROP TYPE "projects_status_enum"`);
    await queryRunner.query(`DROP TYPE "projects_type_enum"`);

    await queryRunner.query(`DROP TABLE "services"`);
    await queryRunner.query(`DROP TABLE "clients"`);
  }
}
