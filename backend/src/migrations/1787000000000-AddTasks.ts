import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddTasks1787000000000 implements MigrationInterface {
  name = 'AddTasks1787000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "tasks_priority_enum" AS ENUM('low', 'medium', 'high', 'urgent')`,
    );
    await queryRunner.query(
      `CREATE TYPE "tasks_status_enum" AS ENUM('todo', 'in_progress', 'pending', 'completed', 'cancelled')`,
    );
    await queryRunner.query(
      `CREATE TABLE "tasks" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "title" character varying NOT NULL, "description" text, "assigneeEmployeeId" uuid NOT NULL, "assignedByUserId" uuid NOT NULL, "assignedByName" character varying NOT NULL, "priority" "tasks_priority_enum" NOT NULL DEFAULT 'medium', "dueDate" date NOT NULL, "status" "tasks_status_enum" NOT NULL DEFAULT 'todo', "completedAt" TIMESTAMP WITH TIME ZONE, CONSTRAINT "PK_tasks_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_tasks_assigneeEmployeeId" ON "tasks" ("assigneeEmployeeId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "tasks" ADD CONSTRAINT "FK_tasks_assigneeEmployeeId" FOREIGN KEY ("assigneeEmployeeId") REFERENCES "employees"("id") ON DELETE RESTRICT ON UPDATE NO ACTION`,
    );

    await queryRunner.query(
      `CREATE TABLE "task_comments" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "taskId" uuid NOT NULL, "authorUserId" uuid NOT NULL, "authorName" character varying NOT NULL, "body" text NOT NULL, CONSTRAINT "PK_task_comments_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_task_comments_taskId" ON "task_comments" ("taskId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "task_comments" ADD CONSTRAINT "FK_task_comments_taskId" FOREIGN KEY ("taskId") REFERENCES "tasks"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );

    await queryRunner.query(
      `CREATE TABLE "task_audit_logs" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "taskId" uuid NOT NULL, "actorUserId" uuid NOT NULL, "actorName" character varying NOT NULL, "fieldLabel" character varying NOT NULL, "oldValue" text, "newValue" text, CONSTRAINT "PK_task_audit_logs_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_task_audit_logs_taskId" ON "task_audit_logs" ("taskId")`,
    );
    await queryRunner.query(
      `ALTER TABLE "task_audit_logs" ADD CONSTRAINT "FK_task_audit_logs_taskId" FOREIGN KEY ("taskId") REFERENCES "tasks"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "task_audit_logs" DROP CONSTRAINT "FK_task_audit_logs_taskId"`,
    );
    await queryRunner.query(`DROP INDEX "IDX_task_audit_logs_taskId"`);
    await queryRunner.query(`DROP TABLE "task_audit_logs"`);

    await queryRunner.query(
      `ALTER TABLE "task_comments" DROP CONSTRAINT "FK_task_comments_taskId"`,
    );
    await queryRunner.query(`DROP INDEX "IDX_task_comments_taskId"`);
    await queryRunner.query(`DROP TABLE "task_comments"`);

    await queryRunner.query(
      `ALTER TABLE "tasks" DROP CONSTRAINT "FK_tasks_assigneeEmployeeId"`,
    );
    await queryRunner.query(`DROP INDEX "IDX_tasks_assigneeEmployeeId"`);
    await queryRunner.query(`DROP TABLE "tasks"`);
    await queryRunner.query(`DROP TYPE "tasks_status_enum"`);
    await queryRunner.query(`DROP TYPE "tasks_priority_enum"`);
  }
}
