import { MigrationInterface, QueryRunner } from 'typeorm';

/** These three columns are filtered on constantly — claimable tasks by
 * department, a project's linked tasks, an employee's own task list — but
 * Postgres doesn't auto-index a foreign-key-shaped column just because it
 * has one, so each was a sequential scan until now. */
export class AddTaskIndexes1790300000000 implements MigrationInterface {
  name = 'AddTaskIndexes1790300000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE INDEX "IDX_tasks_assigneeEmployeeId" ON "tasks" ("assigneeEmployeeId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_tasks_departmentId" ON "tasks" ("departmentId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_tasks_projectId" ON "tasks" ("projectId")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "IDX_tasks_projectId"`);
    await queryRunner.query(`DROP INDEX "IDX_tasks_departmentId"`);
    await queryRunner.query(`DROP INDEX "IDX_tasks_assigneeEmployeeId"`);
  }
}
