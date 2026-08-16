import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { resolveActorName } from '../../../core/utils/resolve-actor-name.util';
import {
  USER_REPOSITORY,
  type UserRepository,
} from '../../authentication/domain/repositories/user-repository.interface';
import { EmploymentStatus } from '../../employee/domain/enums/employment-status.enum';
import {
  EMPLOYEE_REPOSITORY,
  type EmployeeRepository,
} from '../../employee/domain/repositories/employee-repository.interface';
import { HolidaysService } from '../../holidays/application/holidays.service';
import { AdjustLeaveBalanceDto } from './dto/adjust-leave-balance.dto';
import { CreateLeaveTypeDto } from './dto/create-leave-type.dto';
import { SubmitLeaveRequestDto } from './dto/submit-leave-request.dto';
import { UpdateLeaveTypeDto } from './dto/update-leave-type.dto';
import { LeaveBalance } from '../domain/entities/leave-balance.entity';
import { LeaveBalanceAdjustment } from '../domain/entities/leave-balance-adjustment.entity';
import { LeaveRequest } from '../domain/entities/leave-request.entity';
import { LeaveType } from '../domain/entities/leave-type.entity';
import { LeaveRequestStatus } from '../domain/enums/leave-request-status.enum';
import {
  LEAVE_BALANCE_ADJUSTMENT_REPOSITORY,
  type LeaveBalanceAdjustmentRepository,
} from '../domain/repositories/leave-balance-adjustment-repository.interface';
import {
  LEAVE_BALANCE_REPOSITORY,
  type LeaveBalanceRepository,
} from '../domain/repositories/leave-balance-repository.interface';
import {
  LEAVE_REQUEST_REPOSITORY,
  type LeaveRequestRepository,
} from '../domain/repositories/leave-request-repository.interface';
import {
  LEAVE_TYPE_REPOSITORY,
  type LeaveTypeRepository,
} from '../domain/repositories/leave-type-repository.interface';
import { LeaveBalanceResponse } from './leave-balance-response.interface';
import { LeaveCalendarEntry } from './leave-calendar-entry.interface';
import { LeaveRequestResponse } from './leave-request-response.interface';
import { toLeaveRequestResponse } from './leave-request.mapper';

const FOREIGN_KEY_VIOLATION = '23503';

@Injectable()
export class LeaveService {
  constructor(
    @Inject(LEAVE_TYPE_REPOSITORY)
    private readonly leaveTypeRepository: LeaveTypeRepository,
    @Inject(LEAVE_BALANCE_REPOSITORY)
    private readonly leaveBalanceRepository: LeaveBalanceRepository,
    @Inject(LEAVE_REQUEST_REPOSITORY)
    private readonly leaveRequestRepository: LeaveRequestRepository,
    @Inject(LEAVE_BALANCE_ADJUSTMENT_REPOSITORY)
    private readonly leaveBalanceAdjustmentRepository: LeaveBalanceAdjustmentRepository,
    @Inject(EMPLOYEE_REPOSITORY)
    private readonly employeeRepository: EmployeeRepository,
    @Inject(USER_REPOSITORY)
    private readonly userRepository: UserRepository,
    private readonly holidaysService: HolidaysService,
  ) {}

  // ---------------------------------------------------------------------
  // Leave types
  // ---------------------------------------------------------------------

  getLeaveTypes(includeArchived = false): Promise<LeaveType[]> {
    return this.leaveTypeRepository.findAll(includeArchived);
  }

  createLeaveType(dto: CreateLeaveTypeDto): Promise<LeaveType> {
    const leaveType = new LeaveType();
    leaveType.name = dto.name;
    leaveType.annualAllowanceDays = dto.annualAllowanceDays.toFixed(1);
    leaveType.carryForwardLimitDays = dto.carryForwardLimitDays?.toFixed(1);
    leaveType.colorHex = dto.colorHex;
    return this.leaveTypeRepository.save(leaveType);
  }

  async updateLeaveType(
    id: string,
    dto: UpdateLeaveTypeDto,
  ): Promise<LeaveType> {
    const leaveType = await this.leaveTypeRepository.findById(id);
    if (!leaveType) throw new NotFoundException('Leave type not found');

    if (dto.name !== undefined) leaveType.name = dto.name;
    if (dto.annualAllowanceDays !== undefined) {
      leaveType.annualAllowanceDays = dto.annualAllowanceDays.toFixed(1);
    }
    if (dto.carryForwardLimitDays !== undefined) {
      leaveType.carryForwardLimitDays = dto.carryForwardLimitDays.toFixed(1);
    }
    if (dto.colorHex !== undefined) leaveType.colorHex = dto.colorHex;
    if (dto.isArchived !== undefined) leaveType.isArchived = dto.isArchived;

    return this.leaveTypeRepository.save(leaveType);
  }

  async removeLeaveType(id: string): Promise<void> {
    const leaveType = await this.leaveTypeRepository.findById(id);
    if (!leaveType) throw new NotFoundException('Leave type not found');

    try {
      await this.leaveTypeRepository.remove(leaveType);
    } catch (error) {
      if (this.isForeignKeyViolation(error)) {
        throw new ConflictException(
          'Cannot delete a leave type that already has leave requests or ' +
            'balances recorded against it. Archive it instead.',
        );
      }
      throw error;
    }
  }

  // ---------------------------------------------------------------------
  // Leave requests — employee-facing
  // ---------------------------------------------------------------------

  async submitLeaveRequest(
    actorUserId: string,
    dto: SubmitLeaveRequestDto,
  ): Promise<LeaveRequestResponse> {
    const employee = await this.employeeRepository.findByUserId(actorUserId);
    if (!employee) throw new NotFoundException('Employee profile not found');

    const leaveType = await this.leaveTypeRepository.findById(dto.leaveTypeId);
    if (!leaveType || leaveType.isArchived) {
      throw new NotFoundException('Leave type not found');
    }

    const start = new Date(`${dto.startDate}T00:00:00Z`);
    const end = new Date(`${dto.endDate}T00:00:00Z`);
    if (end.getTime() < start.getTime()) {
      throw new BadRequestException(
        'End date must be on or after the start date',
      );
    }

    const numberOfDays = await this.countWorkingDays(
      dto.startDate,
      dto.endDate,
    );
    if (numberOfDays === 0) {
      throw new BadRequestException('Selected range contains no working days');
    }

    const year = start.getUTCFullYear();
    const snapshot = await this.resolveBalanceSnapshot(
      employee.id,
      leaveType,
      year,
    );
    const remaining = Number(snapshot.allocated) - Number(snapshot.used);
    if (numberOfDays > remaining) {
      throw new BadRequestException(
        `Insufficient balance: requested ${numberOfDays} day(s), ${remaining} remaining`,
      );
    }

    const request = new LeaveRequest();
    request.employeeId = employee.id;
    request.leaveTypeId = leaveType.id;
    request.startDate = dto.startDate;
    request.endDate = dto.endDate;
    request.numberOfDays = numberOfDays.toFixed(1);
    request.reason = dto.reason;
    // No reporting manager to approve it — skip straight to the HR stage
    // rather than leaving it stuck at SUBMITTED forever.
    request.status = employee.reportingManagerId
      ? LeaveRequestStatus.SUBMITTED
      : LeaveRequestStatus.MANAGER_APPROVED;

    const saved = await this.leaveRequestRepository.save(request);
    const reloaded = await this.leaveRequestRepository.findById(saved.id);
    return toLeaveRequestResponse(reloaded!);
  }

  async cancelLeaveRequest(
    actorUserId: string,
    requestId: string,
  ): Promise<LeaveRequestResponse> {
    const employee = await this.employeeRepository.findByUserId(actorUserId);
    if (!employee) throw new NotFoundException('Employee profile not found');

    const request = await this.leaveRequestRepository.findById(requestId);
    if (!request || request.employeeId !== employee.id) {
      throw new NotFoundException('Leave request not found');
    }
    if (
      request.status !== LeaveRequestStatus.SUBMITTED &&
      request.status !== LeaveRequestStatus.MANAGER_APPROVED
    ) {
      throw new BadRequestException(
        'Only a pending leave request can be cancelled',
      );
    }

    request.status = LeaveRequestStatus.CANCELLED;
    request.cancelledAt = new Date();
    const saved = await this.leaveRequestRepository.save(request);
    return toLeaveRequestResponse(saved);
  }

  async getMyLeaveRequests(actorUserId: string): Promise<LeaveRequestResponse[]> {
    const employee = await this.employeeRepository.findByUserId(actorUserId);
    if (!employee) throw new NotFoundException('Employee profile not found');

    const requests = await this.leaveRequestRepository.findByEmployeeId(
      employee.id,
    );
    return requests.map(toLeaveRequestResponse);
  }

  // ---------------------------------------------------------------------
  // Leave requests — reporting-manager approval (identity-gated, no
  // permission needed — mirrors RequestsService)
  // ---------------------------------------------------------------------

  async getPendingManagerApproval(
    actorUserId: string,
  ): Promise<LeaveRequestResponse[]> {
    const manager = await this.employeeRepository.findByUserId(actorUserId);
    if (!manager) return [];

    const submitted = await this.leaveRequestRepository.findByStatus(
      LeaveRequestStatus.SUBMITTED,
    );
    return submitted
      .filter((request) => request.employee.reportingManagerId === manager.id)
      .map(toLeaveRequestResponse);
  }

  async approveAsManager(
    requestId: string,
    actorUserId: string,
    comment?: string,
  ): Promise<LeaveRequestResponse> {
    const { request, actorName } = await this.loadForManagerDecision(
      requestId,
      actorUserId,
    );

    request.status = LeaveRequestStatus.MANAGER_APPROVED;
    request.managerDecisionAt = new Date();
    request.managerDecisionByName = actorName;
    request.managerComment = comment;

    const saved = await this.leaveRequestRepository.save(request);
    return toLeaveRequestResponse(saved);
  }

  async rejectAsManager(
    requestId: string,
    actorUserId: string,
    comment?: string,
  ): Promise<LeaveRequestResponse> {
    const { request, actorName } = await this.loadForManagerDecision(
      requestId,
      actorUserId,
    );

    request.status = LeaveRequestStatus.REJECTED;
    request.managerDecisionAt = new Date();
    request.managerDecisionByName = actorName;
    request.managerComment = comment;

    const saved = await this.leaveRequestRepository.save(request);
    return toLeaveRequestResponse(saved);
  }

  // ---------------------------------------------------------------------
  // Leave requests — HR/Admin final approval (`leave.manage`)
  // ---------------------------------------------------------------------

  async getPendingHrApproval(): Promise<LeaveRequestResponse[]> {
    const requests = await this.leaveRequestRepository.findByStatus(
      LeaveRequestStatus.MANAGER_APPROVED,
    );
    return requests.map(toLeaveRequestResponse);
  }

  async approveAsHr(
    requestId: string,
    actorUserId: string,
    comment?: string,
  ): Promise<LeaveRequestResponse> {
    const request = await this.loadForHrDecision(requestId);
    const actorName = await resolveActorName(
      this.employeeRepository,
      this.userRepository,
      actorUserId,
    );

    const year = new Date(`${request.startDate}T00:00:00Z`).getUTCFullYear();
    const balance = await this.getOrCreateBalance(
      request.employeeId,
      request.leaveType,
      year,
    );
    const requestedDays = Number(request.numberOfDays);
    const remaining = Number(balance.allocated) - Number(balance.used);
    if (requestedDays > remaining) {
      throw new BadRequestException(
        `Insufficient balance: this request needs ${requestedDays} day(s) but only ${remaining} remain`,
      );
    }
    balance.used = (Number(balance.used) + requestedDays).toFixed(1);
    await this.leaveBalanceRepository.save(balance);

    request.status = LeaveRequestStatus.APPROVED;
    request.hrDecisionAt = new Date();
    request.hrDecisionByName = actorName;
    request.hrComment = comment;

    const saved = await this.leaveRequestRepository.save(request);
    return toLeaveRequestResponse(saved);
  }

  async rejectAsHr(
    requestId: string,
    actorUserId: string,
    comment?: string,
  ): Promise<LeaveRequestResponse> {
    const request = await this.loadForHrDecision(requestId);
    const actorName = await resolveActorName(
      this.employeeRepository,
      this.userRepository,
      actorUserId,
    );

    request.status = LeaveRequestStatus.REJECTED;
    request.hrDecisionAt = new Date();
    request.hrDecisionByName = actorName;
    request.hrComment = comment;

    const saved = await this.leaveRequestRepository.save(request);
    return toLeaveRequestResponse(saved);
  }

  // ---------------------------------------------------------------------
  // Balances
  // ---------------------------------------------------------------------

  async getMyBalances(actorUserId: string): Promise<LeaveBalanceResponse[]> {
    const employee = await this.employeeRepository.findByUserId(actorUserId);
    if (!employee) throw new NotFoundException('Employee profile not found');
    return this.buildCurrentYearBalances(employee.id);
  }

  async getMyBalanceHistory(
    actorUserId: string,
  ): Promise<LeaveBalanceResponse[]> {
    const employee = await this.employeeRepository.findByUserId(actorUserId);
    if (!employee) throw new NotFoundException('Employee profile not found');
    return this.buildBalanceHistory(employee.id);
  }

  async getEmployeeBalances(
    employeeId: string,
  ): Promise<LeaveBalanceResponse[]> {
    const employee = await this.employeeRepository.findById(employeeId);
    if (!employee) throw new NotFoundException('Employee not found');
    return this.buildBalanceHistory(employeeId);
  }

  async adjustBalance(
    employeeId: string,
    dto: AdjustLeaveBalanceDto,
    actorUserId: string,
  ): Promise<LeaveBalanceResponse> {
    const employee = await this.employeeRepository.findById(employeeId);
    if (!employee) throw new NotFoundException('Employee not found');
    const leaveType = await this.leaveTypeRepository.findById(dto.leaveTypeId);
    if (!leaveType) throw new NotFoundException('Leave type not found');

    const balance = await this.getOrCreateBalance(
      employeeId,
      leaveType,
      dto.year,
    );
    balance.allocated = (Number(balance.allocated) + dto.deltaDays).toFixed(1);
    const saved = await this.leaveBalanceRepository.save(balance);

    const actorName = await resolveActorName(
      this.employeeRepository,
      this.userRepository,
      actorUserId,
    );
    const adjustment = new LeaveBalanceAdjustment();
    adjustment.employeeId = employeeId;
    adjustment.leaveTypeId = dto.leaveTypeId;
    adjustment.year = dto.year;
    adjustment.deltaDays = dto.deltaDays.toFixed(1);
    adjustment.reason = dto.reason;
    adjustment.actorUserId = actorUserId;
    adjustment.actorName = actorName;
    await this.leaveBalanceAdjustmentRepository.save(adjustment);

    return {
      leaveTypeId: leaveType.id,
      leaveTypeName: leaveType.name,
      colorHex: leaveType.colorHex ?? null,
      year: dto.year,
      allocated: Number(saved.allocated),
      used: Number(saved.used),
      remaining: Number(saved.allocated) - Number(saved.used),
    };
  }

  // ---------------------------------------------------------------------
  // Annual reset
  // ---------------------------------------------------------------------

  async getResetStatus(): Promise<{ year: number; isInitialized: boolean }> {
    const year = new Date().getUTCFullYear();
    const balances = await this.leaveBalanceRepository.findByYear(year);
    return { year, isInitialized: balances.length > 0 };
  }

  async runAnnualReset(): Promise<{ year: number; balancesCreated: number }> {
    const year = new Date().getUTCFullYear();
    const [employees, leaveTypes, existing] = await Promise.all([
      this.employeeRepository.findAll(),
      this.leaveTypeRepository.findAll(false),
      this.leaveBalanceRepository.findByYear(year),
    ]);
    const existingKeys = new Set(
      existing.map((b) => `${b.employeeId}:${b.leaveTypeId}`),
    );
    const activeEmployees = employees.filter(
      (employee) => employee.employmentStatus === EmploymentStatus.ACTIVE,
    );

    const toCreate: LeaveBalance[] = [];
    for (const employee of activeEmployees) {
      for (const leaveType of leaveTypes) {
        if (existingKeys.has(`${employee.id}:${leaveType.id}`)) continue;

        const carryForward = leaveType.carryForwardLimitDays
          ? await this.resolveCarryForward(employee.id, leaveType, year - 1)
          : 0;

        const balance = new LeaveBalance();
        balance.employeeId = employee.id;
        balance.leaveTypeId = leaveType.id;
        balance.year = year;
        balance.allocated = (
          Number(leaveType.annualAllowanceDays) + carryForward
        ).toFixed(1);
        balance.used = '0.0';
        toCreate.push(balance);
      }
    }

    if (toCreate.length > 0) {
      await this.leaveBalanceRepository.saveMany(toCreate);
    }
    return { year, balancesCreated: toCreate.length };
  }

  // ---------------------------------------------------------------------
  // Calendar
  // ---------------------------------------------------------------------

  async getLeaveCalendar(
    actorUserId: string,
    scope: 'team' | 'company',
    month: number,
    year: number,
  ): Promise<LeaveCalendarEntry[]> {
    const rangeStart = new Date(Date.UTC(year, month - 1, 1));
    const rangeEnd = new Date(Date.UTC(year, month, 0));

    const requests = await this.leaveRequestRepository.findByStatuses([
      LeaveRequestStatus.APPROVED,
      LeaveRequestStatus.MANAGER_APPROVED,
    ]);

    let scoped = requests;
    if (scope === 'team') {
      const viewer = await this.employeeRepository.findByUserId(actorUserId);
      if (!viewer) return [];
      const directReports = await this.employeeRepository.findByReportingManagerId(
        viewer.id,
      );
      const teamIds = new Set([viewer.id, ...directReports.map((e) => e.id)]);
      scoped = requests.filter((request) => teamIds.has(request.employeeId));
    }

    return scoped
      .filter((request) => {
        const start = new Date(`${request.startDate}T00:00:00Z`);
        const end = new Date(`${request.endDate}T00:00:00Z`);
        return start.getTime() <= rangeEnd.getTime() && end.getTime() >= rangeStart.getTime();
      })
      .map((request) => ({
        employeeId: request.employeeId,
        employeeName: `${request.employee.firstName} ${request.employee.lastName}`,
        employeePhotoUrl: request.employee.profilePhotoUrl ?? null,
        leaveTypeId: request.leaveTypeId,
        leaveTypeName: request.leaveType.name,
        colorHex: request.leaveType.colorHex ?? null,
        startDate: request.startDate,
        endDate: request.endDate,
        isPending: request.status === LeaveRequestStatus.MANAGER_APPROVED,
      }));
  }

  // ---------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------

  /** Working days (Mon-Fri, excluding public holidays) between two ISO
   * dates, inclusive. Dates are parsed as UTC midnight throughout to keep
   * day-of-week checks stable regardless of the server's local timezone. */
  private async countWorkingDays(
    startDate: string,
    endDate: string,
  ): Promise<number> {
    const holidayDates = new Set(
      await this.holidaysService.getDatesInRange(startDate, endDate),
    );

    const cursor = new Date(`${startDate}T00:00:00Z`);
    const end = new Date(`${endDate}T00:00:00Z`);
    let count = 0;
    while (cursor.getTime() <= end.getTime()) {
      const day = cursor.getUTCDay();
      const isWeekend = day === 0 || day === 6;
      const isHoliday = holidayDates.has(cursor.toISOString().slice(0, 10));
      if (!isWeekend && !isHoliday) count++;
      cursor.setUTCDate(cursor.getUTCDate() + 1);
    }
    return count;
  }

  /** A read-only view of an employee's balance for a leave type/year,
   * without persisting anything — used wherever we only need to check
   * remaining balance, not mutate it. */
  private async resolveBalanceSnapshot(
    employeeId: string,
    leaveType: LeaveType,
    year: number,
  ): Promise<{ allocated: string; used: string }> {
    const existing = await this.leaveBalanceRepository.findOne(
      employeeId,
      leaveType.id,
      year,
    );
    return existing ?? { allocated: leaveType.annualAllowanceDays, used: '0.0' };
  }

  /** Same lookup as [resolveBalanceSnapshot], but returns a real (possibly
   * new, unsaved) entity for callers that are about to mutate and save it —
   * this is the only place a LeaveBalance row actually gets persisted for
   * the first time. */
  private async getOrCreateBalance(
    employeeId: string,
    leaveType: LeaveType,
    year: number,
  ): Promise<LeaveBalance> {
    const existing = await this.leaveBalanceRepository.findOne(
      employeeId,
      leaveType.id,
      year,
    );
    if (existing) return existing;

    const balance = new LeaveBalance();
    balance.employeeId = employeeId;
    balance.leaveTypeId = leaveType.id;
    balance.year = year;
    balance.allocated = leaveType.annualAllowanceDays;
    balance.used = '0.0';
    return balance;
  }

  private async resolveCarryForward(
    employeeId: string,
    leaveType: LeaveType,
    previousYear: number,
  ): Promise<number> {
    const previous = await this.leaveBalanceRepository.findOne(
      employeeId,
      leaveType.id,
      previousYear,
    );
    if (!previous || !leaveType.carryForwardLimitDays) return 0;

    const previousRemaining = Math.max(
      0,
      Number(previous.allocated) - Number(previous.used),
    );
    return Math.min(Number(leaveType.carryForwardLimitDays), previousRemaining);
  }

  private async buildCurrentYearBalances(
    employeeId: string,
  ): Promise<LeaveBalanceResponse[]> {
    const year = new Date().getUTCFullYear();
    const [leaveTypes, existing] = await Promise.all([
      this.leaveTypeRepository.findAll(false),
      this.leaveBalanceRepository.findByEmployeeId(employeeId),
    ]);
    const existingByType = new Map(
      existing.filter((b) => b.year === year).map((b) => [b.leaveTypeId, b]),
    );

    return leaveTypes.map((type) => {
      const balance = existingByType.get(type.id);
      const allocated = Number(balance?.allocated ?? type.annualAllowanceDays);
      const used = Number(balance?.used ?? 0);
      return {
        leaveTypeId: type.id,
        leaveTypeName: type.name,
        colorHex: type.colorHex ?? null,
        year,
        allocated,
        used,
        remaining: allocated - used,
      };
    });
  }

  private async buildBalanceHistory(
    employeeId: string,
  ): Promise<LeaveBalanceResponse[]> {
    const currentYear = new Date().getUTCFullYear();
    const currentYearBalances = await this.buildCurrentYearBalances(employeeId);

    const persisted = await this.leaveBalanceRepository.findByEmployeeId(
      employeeId,
    );
    const priorYears = persisted
      .filter((balance) => balance.year !== currentYear)
      .map((balance) => ({
        leaveTypeId: balance.leaveTypeId,
        leaveTypeName: balance.leaveType.name,
        colorHex: balance.leaveType.colorHex ?? null,
        year: balance.year,
        allocated: Number(balance.allocated),
        used: Number(balance.used),
        remaining: Number(balance.allocated) - Number(balance.used),
      }));

    return [...currentYearBalances, ...priorYears].sort(
      (a, b) => b.year - a.year,
    );
  }

  private async loadForManagerDecision(
    requestId: string,
    actorUserId: string,
  ): Promise<{ request: LeaveRequest; actorName: string }> {
    const request = await this.leaveRequestRepository.findById(requestId);
    if (!request) throw new NotFoundException('Leave request not found');
    if (request.status !== LeaveRequestStatus.SUBMITTED) {
      throw new BadRequestException(
        'This request has already moved past the manager approval stage',
      );
    }

    const manager = await this.employeeRepository.findByUserId(actorUserId);
    if (!manager || request.employee.reportingManagerId !== manager.id) {
      throw new ForbiddenException(
        "You aren't the reporting manager for this request",
      );
    }

    return { request, actorName: `${manager.firstName} ${manager.lastName}` };
  }

  private async loadForHrDecision(requestId: string): Promise<LeaveRequest> {
    const request = await this.leaveRequestRepository.findById(requestId);
    if (!request) throw new NotFoundException('Leave request not found');
    if (request.status !== LeaveRequestStatus.MANAGER_APPROVED) {
      throw new BadRequestException(
        'This request is not awaiting HR approval',
      );
    }
    return request;
  }

  private isForeignKeyViolation(error: unknown): boolean {
    const code =
      (error as { code?: string })?.code ??
      (error as { driverError?: { code?: string } })?.driverError?.code;
    return code === FOREIGN_KEY_VIOLATION;
  }
}
