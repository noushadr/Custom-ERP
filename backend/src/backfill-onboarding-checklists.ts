import { NestFactory } from '@nestjs/core';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AppModule } from './app.module';
import { ChecklistsService } from './features/checklists/application/checklists.service';
import { ChecklistType } from './features/checklists/domain/enums/checklist-type.enum';
import { Employee } from './features/employee/domain/entities/employee.entity';
import { EmploymentStatus } from './features/employee/domain/enums/employment-status.enum';

/** One-time data fix for employees who existed before the onboarding/
 * offboarding checklist feature shipped: they never got a checklist instance
 * created for them at all (that only happens on invite / status-change), so
 * their profile showed an empty, invisible checklist section. This creates
 * their onboarding checklist — and offboarding, if they'd already left before
 * this feature existed — with every item pre-marked complete, since they
 * already went through those steps in reality. Idempotent via
 * ChecklistsService.createInstance, so it's safe to re-run. */
async function backfill() {
  const app = await NestFactory.createApplicationContext(AppModule);

  const employeeRepo = app.get<Repository<Employee>>(
    getRepositoryToken(Employee),
  );
  const checklistsService = app.get(ChecklistsService);

  const employees = await employeeRepo.find();
  const leavingStatuses = new Set([
    EmploymentStatus.NOTICE_PERIOD,
    EmploymentStatus.RESIGNED,
    EmploymentStatus.TERMINATED,
  ]);

  let onboardingCreated = 0;
  let offboardingCreated = 0;

  for (const employee of employees) {
    const existingOnboarding = await checklistsService.getEmployeeChecklist(
      employee.id,
      ChecklistType.ONBOARDING,
    );
    if (existingOnboarding.length === 0) {
      await checklistsService.createInstance(
        employee.id,
        ChecklistType.ONBOARDING,
        employee.workMode,
        true,
      );
      onboardingCreated += 1;
      console.log(`Onboarding backfilled: ${employee.employeeCode}`);
    }

    if (leavingStatuses.has(employee.employmentStatus)) {
      const existingOffboarding = await checklistsService.getEmployeeChecklist(
        employee.id,
        ChecklistType.OFFBOARDING,
      );
      if (existingOffboarding.length === 0) {
        await checklistsService.createInstance(
          employee.id,
          ChecklistType.OFFBOARDING,
          employee.workMode,
          true,
        );
        offboardingCreated += 1;
        console.log(`Offboarding backfilled: ${employee.employeeCode}`);
      }
    }
  }

  console.log(
    `Done. Onboarding backfilled for ${onboardingCreated} employee(s), ` +
      `offboarding backfilled for ${offboardingCreated} employee(s).`,
  );

  await app.close();
}

backfill().catch((error) => {
  console.error('Backfill failed:', error);
  process.exit(1);
});
