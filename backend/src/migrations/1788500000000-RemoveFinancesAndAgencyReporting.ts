import { MigrationInterface, QueryRunner } from 'typeorm';

/** Removes the Finances and Agency Reporting modules entirely, per explicit
 * instruction — the app keeps Clients & Projects, Tasks, and Payroll only.
 * Agency Reporting introduced no schema of its own (it only read existing
 * Client/Project fields), so this only needs to reverse Finances' own
 * `expenses` table — `Client.archivedAt` and `Project.paymentStatus`/
 * `amountPaid` are genuine Clients & Projects columns (read/written by
 * ProjectDetailPage's own "Update Payment" dialog and the client
 * archive/unarchive flow) and stay untouched. */
export class RemoveFinancesAndAgencyReporting1788500000000
  implements MigrationInterface
{
  name = 'RemoveFinancesAndAgencyReporting1788500000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "expenses"`);
    await queryRunner.query(`DROP TYPE "expense_category_enum"`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "expense_category_enum" AS ENUM('rent_utilities', 'software_tools', 'marketing', 'vendor_payment', 'taxes', 'commissions', 'other')`,
    );
    await queryRunner.query(
      `CREATE TABLE "expenses" ("id" uuid NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "category" "expense_category_enum" NOT NULL, "amount" numeric(12,2) NOT NULL, "date" date NOT NULL, "payeeName" character varying, "notes" text, CONSTRAINT "PK_expenses_id" PRIMARY KEY ("id"))`,
    );
  }
}
