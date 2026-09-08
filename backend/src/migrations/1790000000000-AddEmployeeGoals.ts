import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddEmployeeGoals1790000000000 implements MigrationInterface {
  name = 'AddEmployeeGoals1790000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "employee_goals" (
        "id" uuid NOT NULL,
        "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "employeeId" uuid NOT NULL,
        "title" character varying NOT NULL,
        "description" text,
        "createdByUserId" uuid NOT NULL,
        "createdByName" character varying NOT NULL,
        CONSTRAINT "PK_employee_goals_id" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      ALTER TABLE "employee_goals"
      ADD CONSTRAINT "FK_employee_goals_employee"
      FOREIGN KEY ("employeeId") REFERENCES "employees"("id") ON DELETE CASCADE
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "employee_goals"`);
  }
}
