import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddTaskProjectId1787300000000 implements MigrationInterface {
  name = 'AddTaskProjectId1787300000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "tasks" ADD "projectId" character varying`);
    await queryRunner.query(
      `CREATE INDEX "IDX_tasks_projectId" ON "tasks" ("projectId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "tasks" ADD CONSTRAINT "FK_tasks_projectId" FOREIGN KEY ("projectId") REFERENCES "projects"("id") ON DELETE SET NULL ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "tasks" DROP CONSTRAINT "FK_tasks_projectId"`,
    );
    await queryRunner.query(`DROP INDEX "IDX_tasks_projectId"`);
    await queryRunner.query(`ALTER TABLE "tasks" DROP COLUMN "projectId"`);
  }
}
