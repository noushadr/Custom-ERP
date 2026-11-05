import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { resolveActorName } from '../../../core/utils/resolve-actor-name.util';
import {
  USER_REPOSITORY,
  type UserRepository,
} from '../../authentication/domain/repositories/user-repository.interface';
import { AttendanceService } from '../../attendance/application/attendance.service';
import { RolesService } from '../../authentication/application/roles.service';
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
import {
  toPayrollLineItemResponse,
  toPayrollRunDetail,
  toPayrollRunSummary,
} from './payroll.mapper';
import { generatePayslipPdf } from './payslip.generator';
import { PayslipListItemDto } from './payroll-response.interface';

/** Last calendar day of [month] (1-12) in [year], as 'YYYY-MM-DD' — plain
 * arithmetic, no Date-to-string timezone conversion involved. */
function endOfMonthIso(year: number, month: number): string {
  const lastDay = new Date(year, month, 0).getDate();
  return `${year}-${String(month).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`;
}

const MONTH_NAMES = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
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
    private readonly attendanceService: AttendanceService,
    private readonly rolesService: RolesService,
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

    const allItems = await Promise.all(
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
        item.fines = [];
        item.freelanceTasks = [];
        item.lateDays = 0;
        item.lateDeductionDays = 0;
        item.lateHours = '0.00';
        item.absentDays = 0;
        item.advanceSalary = '0.00';
        return item;
      }),
    );
    // Someone with no salary on file (e.g. the owner) isn't on payroll.
    const lineItems = allItems.filter((item) => Number(item.baseSalary) > 0);
    await this.applyAttendance(lineItems, dto.month, dto.year);
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
      throw new BadRequestException('Only a draft payroll run can be edited.');
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
    const cleanEntries = (list: { description: string; amount: number }[]) =>
      list.map((entry) => ({
        description: entry.description.trim(),
        amount: Math.round(entry.amount * 100) / 100,
      }));
    if (dto.fines !== undefined) item.fines = cleanEntries(dto.fines);
    if (dto.freelanceTasks !== undefined) {
      item.freelanceTasks = cleanEntries(dto.freelanceTasks);
    }
    if (dto.absentDays !== undefined) {
      if (item.freelancerId != null) {
        throw new BadRequestException("A freelancer has no absent days.");
      }
      item.absentDays = dto.absentDays;
    }
    if (dto.advanceSalary !== undefined) {
      item.advanceSalary = dto.advanceSalary.toFixed(2);
    }
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
      throw new BadRequestException('Only a draft payroll run can be edited.');
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
    item.fines = [];
    item.freelanceTasks = [];
    item.lateDays = 0;
    item.lateDeductionDays = 0;
    item.lateHours = '0.00';
    item.absentDays = 0;
    item.advanceSalary = '0.00';
    item.notes = dto.notes ?? null;
    await this.lineItemRepository.save(item);

    const lineItems = await this.lineItemRepository.findByRunId(runId);
    return toPayrollRunDetail(run, lineItems);
  }

  /** Re-reads the attendance for this run's month and refreshes every
   * employee's late days, late hours and late deduction — for after attendance or work-
   * from-home days were edited. Fines and freelance tasks are untouched. */
  async syncRun(id: string): Promise<PayrollRunDetailDto> {
    const run = await this.getRunOrThrow(id);
    if (run.status !== PayrollRunStatus.DRAFT) {
      throw new BadRequestException(
        'Only a draft payroll run can be synced with attendance.',
      );
    }
    const items = await this.lineItemRepository.findByRunId(run.id);
    await this.applyAttendance(items, run.month, run.year);
    await this.lineItemRepository.saveMany(items);
    return toPayrollRunDetail(
      run,
      await this.lineItemRepository.findByRunId(run.id),
    );
  }

  /** On the 1st of every month, reminds everyone who manages payroll to
   * generate the run for the month that just ended (unless it exists). */
  @Cron('0 9 1 * *')
  async handleMonthlyPayrollReminder(): Promise<void> {
    const now = new Date();
    const previous = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const month = previous.getMonth() + 1;
    const year = previous.getFullYear();
    if (await this.runRepository.findByMonthYear(month, year)) return;

    const managers =
      await this.rolesService.findUsersWithPermission('payroll.manage');
    for (const manager of managers) {
      await this.notificationsService.create({
        recipientUserId: manager.id,
        message: `It's the 1st — generate the payroll for ${MONTH_NAMES[month - 1]} ${year}.`,
      });
    }
  }

  /** Sets each employee line item's late days / late-deduction days from the
   * attendance for [month]/[year]. Freshens the machine data first (it
   * silently falls back to what is already stored if the machine is down),
   * and leaves anyone not tracked by attendance at zero. */
  private async applyAttendance(
    items: PayrollLineItem[],
    month: number,
    year: number,
  ): Promise<void> {
    try {
      await this.attendanceService.refreshIfStale();
    } catch {
      // Use whatever attendance is already stored.
    }
    const attendance = await this.attendanceService.getCompanyMonth(
      month,
      year,
    );
    const byEmployee = new Map(attendance.map((a) => [a.employeeId, a]));
    for (const item of items) {
      if (item.employeeId == null) continue;
      const tracked = byEmployee.get(item.employeeId);
      item.lateDays = tracked?.linked ? tracked.summary.late : 0;
      item.lateDeductionDays = tracked?.linked
        ? tracked.summary.lateDeductionDays
        : 0;
      item.lateHours = (
        tracked?.linked ? tracked.summary.hoursCutMinutes / 60 : 0
      ).toFixed(2);
    }
  }

  async finalizeRun(
    id: string,
    actorUserId: string,
  ): Promise<PayrollRunSummaryDto> {
    const run = await this.getRunOrThrow(id);
    if (run.status !== PayrollRunStatus.DRAFT) {
      throw new BadRequestException(
        'Only a draft payroll run can be finalized.',
      );
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

  /** HR/Admin path: any employee's payslip for a Paid run. */
  async getPayslipPdf(
    runId: string,
    lineItemId: string,
  ): Promise<{ buffer: Buffer; filename: string }> {
    const run = await this.getRunOrThrow(runId);
    const item = await this.getPayableLineItemOrThrow(run, lineItemId);
    return this.renderPayslip(run, item);
  }

  /** HR/Admin path: a specific employee's payslips across every Paid run —
   * same scan-every-Paid-run shape as `getMyPayslips`, just keyed directly
   * off the given employee id instead of resolving it from the caller's own
   * JWT. Used by the Employee Profile page's Payslips section. */
  async getEmployeePayslips(employeeId: string): Promise<PayslipListItemDto[]> {
    const runs = (await this.runRepository.findAll()).filter(
      (run) => run.status === PayrollRunStatus.PAID,
    );

    const results: PayslipListItemDto[] = [];
    for (const run of runs) {
      const lineItems = await this.lineItemRepository.findByRunId(run.id);
      const own = lineItems.find((item) => item.employeeId === employeeId);
      if (!own) continue;
      results.push({
        runId: run.id,
        lineItemId: own.id,
        month: run.month,
        year: run.year,
        netPay: toPayrollLineItemResponse(own).netPay,
        paidAt: run.paidAt!.toISOString(),
      });
    }

    return results.sort((a, b) =>
      a.year !== b.year ? b.year - a.year : b.month - a.month,
    );
  }

  /** Self-service path: the caller's own line items across every Paid run,
   * newest period first — computed by scanning every Paid run rather than a
   * dedicated query, matching this app's established "filter client/
   * service-side over a small, bounded dataset" convention (payroll runs
   * are monthly, so this never scans more than a couple dozen rows). */
  async getMyPayslips(actorUserId: string): Promise<PayslipListItemDto[]> {
    const employee = await this.employeeRepository.findByUserId(actorUserId);
    if (!employee) return [];
    return this.getEmployeePayslips(employee.id);
  }

  /** Self-service path: the caller's own payslip PDF — refuses anything
   * that isn't the caller's own line item, regardless of what id is
   * requested. */
  async getMyPayslipPdf(
    actorUserId: string,
    lineItemId: string,
  ): Promise<{ buffer: Buffer; filename: string }> {
    const employee = await this.employeeRepository.findByUserId(actorUserId);
    if (!employee) throw new NotFoundException('Employee profile not found');

    const item = await this.lineItemRepository.findById(lineItemId);
    if (!item || item.employeeId !== employee.id) {
      throw new NotFoundException('Payslip not found');
    }

    const run = await this.getRunOrThrow(item.runId);
    const payableItem = await this.getPayableLineItemOrThrow(run, item.id);
    return this.renderPayslip(run, payableItem);
  }

  private async getPayableLineItemOrThrow(
    run: PayrollRun,
    lineItemId: string,
  ): Promise<PayrollLineItem> {
    if (run.status !== PayrollRunStatus.PAID) {
      throw new BadRequestException(
        'A payslip is only available once its payroll run is marked Paid.',
      );
    }

    const item = await this.lineItemRepository.findById(lineItemId);
    if (!item || item.runId !== run.id) {
      throw new NotFoundException('Payroll line item not found');
    }
    if (item.employeeId == null) {
      throw new BadRequestException(
        'Freelancers have no ERP login and no payslip.',
      );
    }

    return item;
  }

  private async renderPayslip(
    run: PayrollRun,
    item: PayrollLineItem,
  ): Promise<{ buffer: Buffer; filename: string }> {
    const buffer = await generatePayslipPdf(run, item);
    const employee = item.employee!;
    const filename = `Payslip-${employee.employeeCode}-${run.year}-${String(run.month).padStart(2, '0')}.pdf`;
    return { buffer, filename };
  }

  private async getRunOrThrow(id: string): Promise<PayrollRun> {
    const run = await this.runRepository.findById(id);
    if (!run) throw new NotFoundException('Payroll run not found');
    return run;
  }
}
