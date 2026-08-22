import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { resolveActorName } from '../../../core/utils/resolve-actor-name.util';
import {
  USER_REPOSITORY,
  type UserRepository,
} from '../../authentication/domain/repositories/user-repository.interface';
import { EmployeesService } from '../../employee/application/employees.service';
import { EmploymentStatus } from '../../employee/domain/enums/employment-status.enum';
import {
  EMPLOYEE_REPOSITORY,
  type EmployeeRepository,
} from '../../employee/domain/repositories/employee-repository.interface';
import { GeneratePayrollRunDto } from './dto/generate-payroll-run.dto';
import { UpdatePayrollLineItemDto } from './dto/update-payroll-line-item.dto';
import { PayrollLineItem } from '../domain/entities/payroll-line-item.entity';
import { PayrollRun } from '../domain/entities/payroll-run.entity';
import { PayrollRunStatus } from '../domain/enums/payroll-run-status.enum';
import {
  PAYROLL_LINE_ITEM_REPOSITORY,
  type PayrollLineItemRepository,
} from '../domain/repositories/payroll-line-item-repository.interface';
import {
  PAYROLL_RUN_REPOSITORY,
  type PayrollRunRepository,
} from '../domain/repositories/payroll-run-repository.interface';
import {
  PayrollRunDetailDto,
  PayrollRunSummaryDto,
} from './payroll-response.interface';
import { toPayrollRunDetail, toPayrollRunSummary } from './payroll.mapper';

/** Last calendar day of [month] (1-12) in [year], as 'YYYY-MM-DD' — plain
 * arithmetic, no Date-to-string timezone conversion involved. */
function endOfMonthIso(year: number, month: number): string {
  const lastDay = new Date(year, month, 0).getDate();
  return `${year}-${String(month).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`;
}

@Injectable()
export class PayrollService {
  constructor(
    @Inject(PAYROLL_RUN_REPOSITORY)
    private readonly runRepository: PayrollRunRepository,
    @Inject(PAYROLL_LINE_ITEM_REPOSITORY)
    private readonly lineItemRepository: PayrollLineItemRepository,
    @Inject(EMPLOYEE_REPOSITORY)
    private readonly employeeRepository: EmployeeRepository,
    @Inject(USER_REPOSITORY)
    private readonly userRepository: UserRepository,
    private readonly employeesService: EmployeesService,
  ) {}

  async getRuns(): Promise<PayrollRunSummaryDto[]> {
    const runs = await this.runRepository.findAll();
    return Promise.all(
      runs.map(async (run) =>
        toPayrollRunSummary(
          run,
          await this.lineItemRepository.findByRunId(run.id),
        ),
      ),
    );
  }

  async getRun(id: string): Promise<PayrollRunDetailDto> {
    const run = await this.getRunOrThrow(id);
    const lineItems = await this.lineItemRepository.findByRunId(run.id);
    return toPayrollRunDetail(run, lineItems);
  }

  /** Creates one PayrollRun for [dto.month]/[dto.year] plus one
   * PayrollLineItem per currently-active employee, with `baseSalary`
   * snapshotted from their salary history as of that month's last day —
   * never recomputed afterwards. Refuses to create a second run for the
   * same month/year (an explicit conflict, not silent, since this is an
   * admin-triggered action rather than an automatic daily check). */
  async generateRun(
    dto: GeneratePayrollRunDto,
    actorUserId: string,
  ): Promise<PayrollRunDetailDto> {
    const existing = await this.runRepository.findByMonthYear(
      dto.month,
      dto.year,
    );
    if (existing) {
      throw new ConflictException(
        `A payroll run for ${dto.month}/${dto.year} already exists.`,
      );
    }

    const actorName = await resolveActorName(
      this.employeeRepository,
      this.userRepository,
      actorUserId,
    );

    const run = new PayrollRun();
    run.month = dto.month;
    run.year = dto.year;
    run.status = PayrollRunStatus.DRAFT;
    run.generatedByName = actorName;
    const savedRun = await this.runRepository.save(run);

    const employees = await this.employeeRepository.findAll();
    const activeEmployees = employees.filter(
      (employee) => employee.employmentStatus === EmploymentStatus.ACTIVE,
    );
    const asOfIsoDate = endOfMonthIso(dto.year, dto.month);

    const lineItems = await Promise.all(
      activeEmployees.map(async (employee) => {
        const baseSalary = await this.employeesService.getSalaryAsOf(
          employee.id,
          asOfIsoDate,
        );
        const item = new PayrollLineItem();
        item.runId = savedRun.id;
        item.employeeId = employee.id;
        item.baseSalary = baseSalary.toFixed(2);
        item.bonuses = '0.00';
        item.allowances = '0.00';
        item.overtime = '0.00';
        item.deductions = '0.00';
        item.advances = '0.00';
        item.tax = '0.00';
        return item;
      }),
    );
    await this.lineItemRepository.saveMany(lineItems);
    // saveMany's returned rows don't carry the eager-loaded `employee`
    // relation the mapper needs (employeeName/photo) — re-fetch the whole
    // run's items in one query rather than hydrating each individually.
    const savedItems = await this.lineItemRepository.findByRunId(savedRun.id);

    return toPayrollRunDetail(savedRun, savedItems);
  }

  async updateLineItem(
    runId: string,
    lineItemId: string,
    dto: UpdatePayrollLineItemDto,
  ): Promise<PayrollRunDetailDto> {
    const run = await this.getRunOrThrow(runId);
    if (run.status !== PayrollRunStatus.DRAFT) {
      throw new BadRequestException(
        'Only a draft payroll run can be edited.',
      );
    }

    const item = await this.lineItemRepository.findById(lineItemId);
    if (!item || item.runId !== runId) {
      throw new NotFoundException('Payroll line item not found');
    }

    if (dto.bonuses !== undefined) item.bonuses = dto.bonuses.toFixed(2);
    if (dto.allowances !== undefined) {
      item.allowances = dto.allowances.toFixed(2);
    }
    if (dto.overtime !== undefined) item.overtime = dto.overtime.toFixed(2);
    if (dto.deductions !== undefined) {
      item.deductions = dto.deductions.toFixed(2);
    }
    if (dto.advances !== undefined) item.advances = dto.advances.toFixed(2);
    if (dto.tax !== undefined) item.tax = dto.tax.toFixed(2);
    if (dto.notes !== undefined) item.notes = dto.notes;

    await this.lineItemRepository.save(item);

    const lineItems = await this.lineItemRepository.findByRunId(runId);
    return toPayrollRunDetail(run, lineItems);
  }

  async finalizeRun(
    id: string,
    actorUserId: string,
  ): Promise<PayrollRunSummaryDto> {
    const run = await this.getRunOrThrow(id);
    if (run.status !== PayrollRunStatus.DRAFT) {
      throw new BadRequestException('Only a draft payroll run can be finalized.');
    }

    run.status = PayrollRunStatus.FINALIZED;
    run.finalizedByName = await resolveActorName(
      this.employeeRepository,
      this.userRepository,
      actorUserId,
    );
    run.finalizedAt = new Date();
    const saved = await this.runRepository.save(run);

    return toPayrollRunSummary(
      saved,
      await this.lineItemRepository.findByRunId(saved.id),
    );
  }

  async payRun(id: string, actorUserId: string): Promise<PayrollRunSummaryDto> {
    const run = await this.getRunOrThrow(id);
    if (run.status !== PayrollRunStatus.FINALIZED) {
      throw new BadRequestException(
        'Only a finalized payroll run can be marked paid.',
      );
    }

    run.status = PayrollRunStatus.PAID;
    run.paidByName = await resolveActorName(
      this.employeeRepository,
      this.userRepository,
      actorUserId,
    );
    run.paidAt = new Date();
    const saved = await this.runRepository.save(run);

    return toPayrollRunSummary(
      saved,
      await this.lineItemRepository.findByRunId(saved.id),
    );
  }

  private async getRunOrThrow(id: string): Promise<PayrollRun> {
    const run = await this.runRepository.findById(id);
    if (!run) throw new NotFoundException('Payroll run not found');
    return run;
  }
}
