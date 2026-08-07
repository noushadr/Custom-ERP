import { readFileSync } from 'fs';
import { NestFactory } from '@nestjs/core';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AppModule } from './app.module';
import { User } from './features/authentication/domain/entities/user.entity';
import { Employee } from './features/employee/domain/entities/employee.entity';
import { EmployeesService } from './features/employee/application/employees.service';
import { UpdateEmployeeDto } from './features/employee/application/dto/update-employee.dto';

// Cleaned, pre-parsed rows extracted from the client's updated
// "Employee (hr.employee).xlsx" export, keyed by the *current* (fake,
// sequentially-assigned) employeeCode already in the DB. See scratchpad
// xlsx-tool/build_update_source.js for how this was produced and vetted.
const SOURCE_PATH =
  'C:\\Users\\Zera\\AppData\\Local\\Temp\\claude\\C--Users-Zera-Desktop-Zera-ERP\\8d1aa31a-01f5-4952-aa7b-5444529e9984\\scratchpad\\xlsx-tool\\update-source.json';

const SUPER_ADMIN_EMAIL = 'noushad@zeracreative.com';

interface SourceEntry {
  name: string;
  realEmployeeId: string;
  joiningDate: string | null;
  dateOfLeaving: string | null;
  dateOfBirth: string | { unparsed: string } | null;
  personalEmail: string | null;
  phoneNumber: string | { unparsed: string } | null;
  bankName: string | null;
  accountTitle: string | null;
  accountNumber: string | null;
  iban: string | null;
  joiningSalary: number | null;
  currentSalary: number | null;
}

function buildDto(data: SourceEntry): UpdateEmployeeDto {
  const dto: UpdateEmployeeDto = {};
  if (data.joiningDate) dto.joiningDate = data.joiningDate;
  if (data.dateOfLeaving) dto.dateOfLeaving = data.dateOfLeaving;
  if (typeof data.dateOfBirth === 'string') dto.dateOfBirth = data.dateOfBirth;
  if (data.personalEmail) dto.personalEmail = data.personalEmail;
  if (typeof data.phoneNumber === 'string') dto.phoneNumber = data.phoneNumber;
  if (data.bankName) dto.bankName = data.bankName;
  if (data.accountTitle) dto.accountTitle = data.accountTitle;
  if (data.accountNumber) dto.accountNumber = data.accountNumber;
  if (data.iban) dto.iban = data.iban;
  return dto;
}

async function run() {
  const source = JSON.parse(readFileSync(SOURCE_PATH, 'utf-8')) as Record<
    string,
    SourceEntry
  >;

  const app = await NestFactory.createApplicationContext(AppModule);

  const employeeRepo = app.get<Repository<Employee>>(
    getRepositoryToken(Employee),
  );
  const userRepo = app.get<Repository<User>>(getRepositoryToken(User));
  const employeesService = app.get(EmployeesService);

  const actor = await userRepo.findOneOrFail({
    where: { email: SUPER_ADMIN_EMAIL },
  });

  const today = new Date().toISOString().slice(0, 10);

  for (const [oldCode, data] of Object.entries(source)) {
    const employee = await employeeRepo.findOne({
      where: { employeeCode: oldCode },
    });
    if (!employee) {
      console.warn(`Skipping ${data.name}: no employee with code ${oldCode}`);
      continue;
    }

    await employeesService.update(employee.id, buildDto(data), actor.id);
    await employeeRepo.update(employee.id, {
      employeeCode: data.realEmployeeId,
    });

    if (data.joiningSalary && data.currentSalary) {
      if (data.joiningSalary !== data.currentSalary && data.joiningDate) {
        await employeesService.addSalaryRecord(
          employee.id,
          {
            amount: data.joiningSalary,
            effectiveDate: data.joiningDate,
            note: 'Joining salary (from HR import)',
          },
          actor.id,
        );
        await employeesService.addSalaryRecord(
          employee.id,
          {
            amount: data.currentSalary,
            effectiveDate: today,
            note: 'Current salary (from HR import)',
          },
          actor.id,
        );
      } else {
        await employeesService.addSalaryRecord(
          employee.id,
          {
            amount: data.currentSalary,
            effectiveDate: data.joiningDate ?? today,
            note: 'Salary (from HR import)',
          },
          actor.id,
        );
      }
    } else if (data.joiningSalary && data.joiningDate) {
      await employeesService.addSalaryRecord(
        employee.id,
        {
          amount: data.joiningSalary,
          effectiveDate: data.joiningDate,
          note: 'Joining salary (from HR import)',
        },
        actor.id,
      );
    } else if (data.currentSalary) {
      await employeesService.addSalaryRecord(
        employee.id,
        {
          amount: data.currentSalary,
          effectiveDate: today,
          note: 'Current salary (from HR import)',
        },
        actor.id,
      );
    }

    console.log(`Updated ${data.name}: ${oldCode} -> ${data.realEmployeeId}`);
  }

  const allEmployees = await employeeRepo.find();
  const stillFake = allEmployees.filter((e) =>
    /^ZC-\d{5}$/.test(e.employeeCode),
  );
  if (stillFake.length > 0) {
    console.log('\nEmployees NOT found in the spreadsheet (left untouched):');
    for (const e of stillFake) {
      console.log(`  ${e.employeeCode}: ${e.firstName} ${e.lastName}`);
    }
  }

  await app.close();
}

run().catch((error) => {
  console.error('Update failed:', error);
  process.exit(1);
});
