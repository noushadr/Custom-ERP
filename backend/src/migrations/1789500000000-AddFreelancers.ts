import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddFreelancers1789500000000 implements MigrationInterface {
  name = 'AddFreelancers1789500000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "freelancers" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "fullName" character varying NOT NULL, "role" character varying, "notes" text, "isActive" boolean NOT NULL DEFAULT true, CONSTRAINT "PK_freelancers_id" PRIMARY KEY ("id"))`,
    );

    // A payroll line item now belongs to either an Employee or a
    // Freelancer, never both — enforced in PayrollService, not a DB
    // constraint, matching this table's existing employeeId (which also
    // has no FK constraint of its own).
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ALTER COLUMN "employeeId" DROP NOT NULL`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ADD "freelancerId" uuid`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" DROP COLUMN "freelancerId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_line_items" ALTER COLUMN "employeeId" SET NOT NULL`,
    );
    await queryRunner.query(`DROP TABLE "freelancers"`);
  }
}
