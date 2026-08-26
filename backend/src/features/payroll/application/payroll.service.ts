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
import {
  FREELANCER_REPOSITORY,
  type FreelancerRepository,
} from '../../freelancers/domain/repositories/freelancer-repository.interface';
import { NotificationsService } from '../../notifications/application/notifications.service';
import { AddFreelancerLineItemDto } from './dto/add-freelancer-line-item.dto';
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

const MONTH_NAMES = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

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
    @Inject(FREELANCER_REPOSITORY)
    private readonly freelancerRepository: FreelancerRepository,
    private readonly employeesService: EmployeesService,
    private readonly notificationsService: NotificationsService,
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
        item.freelancerId = null;
        item.baseSalary = baseSalary.toFixed(2);
        item.quantity = null;
        item.perUnitRate = null;
        item.allowances = '0.00';
        item.overtime = '0.00';
        item.reimbursement = '0.00';
        item.commissions = '0.00';
        item.deductions = '0.00';
        item.advances = '0.00';
        item.tax = '0.00';
        item.fines = '0.00';
        item.totalAbsent = 0;
        item.lateHours = 0;
        item.lateDays = 0;
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

    if (dto.baseSalary !== undefined) {
      if (item.freelancerId == null) {
        throw new BadRequestException(
          "Only a freelancer's base pay can be edited directly — an " +
            "employee's is snapshotted from their salary record.",
        );
      }
      item.baseSalary = dto.baseSalary.toFixed(2);
    }
    if (dto.quantity !== undefined) item.quantity = dto.quantity;
    if (dto.perUnitRate !== undefined) {
      item.perUnitRate = dto.perUnitRate.toFixed(2);
    }
    if (dto.allowances !== undefined) {
      item.allowances = dto.allowances.toFixed(2);
    }
    if (dto.overtime !== undefined) item.overtime = dto.overtime.toFixed(2);
    if (dto.reimbursement !== undefined) {
      item.reimbursement = dto.reimbursement.toFixed(2);
    }
    if (dto.commissions !== undefined) {
      item.commissions = dto.commissions.toFixed(2);
    }
    if (dto.deductions !== undefined) {
      item.deductions = dto.deductions.toFixed(2);
    }
    if (dto.advances !== undefined) item.advances = dto.advances.toFixed(2);
    if (dto.tax !== undefined) item.tax = dto.tax.toFixed(2);
    if (dto.fines !== undefined) item.fines = dto.fines.toFixed(2);
    if (dto.totalAbsent !== undefined) item.totalAbsent = dto.totalAbsent;
    if (dto.lateHours !== undefined) item.lateHours = dto.lateHours;
    if (dto.lateDays !== undefined) item.lateDays = dto.lateDays;
    if (dto.notes !== undefined) item.notes = dto.notes;

    await this.lineItemRepository.save(item);

    const lineItems = await this.lineItemRepository.findByRunId(runId);
    return toPayrollRunDetail(run, lineItems);
  }

  /** Adds one freelancer to a draft run, with this month's pay entered
   * directly (freelancers have no SalaryRecord to snapshot from — see
   * `PayrollLineItem.baseSalary`'s doc comment). Unlike active employees,
   * freelancers are never auto-included when a run is generated, since
   * whether/how much a given freelancer worked varies month to month. */
  async addFreelancerToRun(
    runId: string,
    dto: AddFreelancerLineItemDto,
  ): Promise<PayrollRunDetailDto> {
    const run = await this.getRunOrThrow(runId);
    if (run.status !== PayrollRunStatus.DRAFT) {
      throw new BadRequestException(
        'Only a draft payroll run can be edited.',
      );
    }

    const freelancer = await this.freelancerRepository.findById(
      dto.freelancerId,
    );
    if (!freelancer) throw new NotFoundException('Freelancer not found');

    const existingItems = await this.lineItemRepository.findByRunId(runId);
    if (existingItems.some((item) => item.freelancerId === dto.freelancerId)) {
      throw new ConflictException(
        `${freelancer.fullName} is already in this payroll run.`,
      );
    }

    const item = new PayrollLineItem();
    item.runId = runId;
    item.employeeId = null;
    item.freelancerId = freelancer.id;
    item.baseSalary = dto.baseSalary.toFixed(2);
    item.quantity = null;
    item.perUnitRate = null;
    item.allowances = '0.00';
    item.overtime = '0.00';
    item.reimbursement = '0.00';
    item.commissions = '0.00';
    item.deductions = '0.00';
    item.advances = '0.00';
    item.tax = '0.00';
    item.fines = '0.00';
    item.totalAbsent = 0;
    item.lateHours = 0;
    item.lateDays = 0;
    item.notes = dto.notes ?? null;
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
    const lineItems = await this.lineItemRepository.findByRunId(saved.id);

    for (const item of lineItems) {
      // Freelancers have no User/login account to notify.
      if (!item.employee) continue;
      await this.notificationsService.create({
        recipientUserId: item.employee.userId,
        message: `Your payroll for ${MONTH_NAMES[saved.month - 1]} ${saved.year} has been paid.`,
      });
    }

    return toPayrollRunSummary(saved, lineItems);
  }

  private async getRunOrThrow(id: string): Promise<PayrollRun> {
    const run = await this.runRepository.findById(id);
    if (!run) throw new NotFoundException('Payroll run not found');
    return run;
  }
}
