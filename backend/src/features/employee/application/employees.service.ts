import { promises as fs } from 'fs';
import { join } from 'path';
import {
  ConflictException,
  Inject,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { ChecklistsService } from '../../checklists/application/checklists.service';
import { SetChecklistItemCompletedDto } from '../../checklists/application/dto/set-checklist-item-completed.dto';
import { EmployeeChecklistItem } from '../../checklists/domain/entities/employee-checklist-item.entity';
import { ChecklistType } from '../../checklists/domain/enums/checklist-type.enum';
import { User } from '../../authentication/domain/entities/user.entity';
import { UserStatus } from '../../authentication/domain/enums/user-status.enum';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import {
  ROLE_REPOSITORY,
  type RoleRepository,
} from '../../authentication/domain/repositories/role-repository.interface';
import {
  USER_REPOSITORY,
  type UserRepository,
} from '../../authentication/domain/repositories/user-repository.interface';
import { Asset } from '../domain/entities/asset.entity';
import { Employee } from '../domain/entities/employee.entity';
import { EmployeeAuditLog } from '../domain/entities/employee-audit-log.entity';
import { EmployeeDocument } from '../domain/entities/employee-document.entity';
import { EducationRecord } from '../domain/entities/education-record.entity';
import { SalaryRecord } from '../domain/entities/salary-record.entity';
import { AssetStatus } from '../domain/enums/asset-status.enum';
import { DocumentType } from '../domain/enums/document-type.enum';
import { EmploymentStatus } from '../domain/enums/employment-status.enum';
import { WorkMode } from '../domain/enums/work-mode.enum';
import {
  EMPLOYEE_REPOSITORY,
  type EmployeeRepository,
} from '../domain/repositories/employee-repository.interface';
import {
  ASSET_REPOSITORY,
  type AssetRepository,
} from '../domain/repositories/asset-repository.interface';
import {
  DOCUMENT_REPOSITORY,
  type DocumentRepository,
} from '../domain/repositories/document-repository.interface';
import {
  AUDIT_LOG_REPOSITORY,
  type AuditLogRepository,
} from '../domain/repositories/audit-log-repository.interface';
import {
  EDUCATION_RECORD_REPOSITORY,
  type EducationRecordRepository,
} from '../domain/repositories/education-record-repository.interface';
import {
  SALARY_RECORD_REPOSITORY,
  type SalaryRecordRepository,
} from '../domain/repositories/salary-record-repository.interface';
import { AssetResponse } from './asset-response.interface';
import { toAssetResponse } from './asset.mapper';
import { AuditLogResponse } from './audit-log-response.interface';
import { toAuditLogResponse } from './audit-log.mapper';
import { PaginatedAuditLogResponse } from './paginated-audit-log-response.interface';
import { DocumentResponse } from './document-response.interface';
import { toDocumentResponse } from './document.mapper';
import { EmployeeResponse } from './employee-response.interface';
import { toEmployeeResponse } from './employee.mapper';
import { definedFieldsOnly } from '../../../core/utils/defined-fields-only.util';
import { generateTemporaryPassword } from '../../../core/utils/generate-temporary-password.util';
import { resolveActorName } from '../../../core/utils/resolve-actor-name.util';
import { AddEducationRecordDto } from './dto/add-education-record.dto';
import { AddSalaryRecordDto } from './dto/add-salary-record.dto';
import { CompanyAuditLogQueryDto } from './dto/company-audit-log-query.dto';
import { CreateAssetDto } from './dto/create-asset.dto';
import { InviteEmployeeDto } from './dto/invite-employee.dto';
import { UpdateAssetDto } from './dto/update-asset.dto';
import { UpdateEmployeeDto } from './dto/update-employee.dto';
import { UpdateMyProfileDto } from './dto/update-my-profile.dto';
import { EducationRecordResponse } from './education-record-response.interface';
import { toEducationRecordResponse } from './education-record.mapper';
import { SalaryRecordResponse } from './salary-record-response.interface';
import { toSalaryRecordResponse } from './salary-record.mapper';
import { PayrollSummaryResponse } from './payroll-summary-response.interface';
import { UpcomingBirthdayResponse } from './upcoming-birthday-response.interface';
import { UpcomingWorkAnniversaryResponse } from './upcoming-work-anniversary-response.interface';

const DEFAULT_INVITE_ROLE = 'Employee';
const COMPANY_AUDIT_LOG_DEFAULT_LIMIT = 10;

const DOCUMENT_TYPE_LABELS: Record<DocumentType, string> = {
  [DocumentType.CONTRACT]: 'Contract',
  [DocumentType.RESUME]: 'Resume',
  [DocumentType.CNIC]: 'CNIC / National ID',
  [DocumentType.OTHER]: 'Document',
};

export interface FieldDiff {
  fieldLabel: string;
  oldValue: string | null;
  newValue: string | null;
}

/** The subset of Employee fields diffed for the audit log — a plain snapshot
 * (not a full Employee instance), since "before" is captured via `{...employee}`. */
type EmployeeSnapshot = Pick<
  Employee,
  | 'firstName'
  | 'lastName'
  | 'designation'
  | 'department'
  | 'employmentType'
  | 'employmentStatus'
  | 'workMode'
  | 'joiningDate'
  | 'dateOfLeaving'
  | 'dateOfBirth'
  | 'personalEmail'
  | 'phoneNumber'
  | 'emergencyContactName'
  | 'emergencyContactPhone'
  | 'emergencyContactRelation'
  | 'address'
  | 'bankName'
  | 'accountTitle'
  | 'accountNumber'
  | 'branchCode'
  | 'iban'
  | 'skills'
  | 'certifications'
  | 'profilePhotoUrl'
  | 'reportingManagerId'
>;

@Injectable()
export class EmployeesService {
  constructor(
    @Inject(EMPLOYEE_REPOSITORY)
    private readonly employeeRepository: EmployeeRepository,
    @Inject(USER_REPOSITORY) private readonly userRepository: UserRepository,
    @Inject(ROLE_REPOSITORY) private readonly roleRepository: RoleRepository,
    @Inject(DOCUMENT_REPOSITORY)
    private readonly documentRepository: DocumentRepository,
    @Inject(AUDIT_LOG_REPOSITORY)
    private readonly auditLogRepository: AuditLogRepository,
    @Inject(SALARY_RECORD_REPOSITORY)
    private readonly salaryRecordRepository: SalaryRecordRepository,
    @Inject(EDUCATION_RECORD_REPOSITORY)
    private readonly educationRecordRepository: EducationRecordRepository,
    @Inject(ASSET_REPOSITORY)
    private readonly assetRepository: AssetRepository,
    private readonly checklistsService: ChecklistsService,
  ) {}

  async invite(
    dto: InviteEmployeeDto,
  ): Promise<{ employee: EmployeeResponse; temporaryPassword: string }> {
    const existingUser = await this.userRepository.findByEmail(
      dto.companyEmail,
    );
    if (existingUser) {
      throw new ConflictException('A user with this email already exists');
    }

    const employeeRole =
      await this.roleRepository.findByName(DEFAULT_INVITE_ROLE);
    if (!employeeRole) {
      throw new InternalServerErrorException(
        `Default "${DEFAULT_INVITE_ROLE}" role is not seeded`,
      );
    }

    const temporaryPassword = generateTemporaryPassword();
    const passwordHash = await bcrypt.hash(temporaryPassword, 10);

    const user = new User();
    user.email = dto.companyEmail;
    user.passwordHash = passwordHash;
    user.roleId = employeeRole.id;
    user.role = employeeRole;
    user.status = UserStatus.PENDING_INVITE;
    const savedUser = await this.userRepository.save(user);

    const employee = new Employee();
    employee.userId = savedUser.id;
    employee.employeeCode = dto.employeeCode ?? (await this.generateEmployeeCode());
    employee.firstName = dto.firstName;
    employee.lastName = dto.lastName;
    employee.designation = dto.designation;
    employee.departmentId = dto.departmentId;
    employee.reportingManagerId = dto.reportingManagerId;
    employee.joiningDate =
      dto.joiningDate ?? new Date().toISOString().slice(0, 10);
    employee.workMode = dto.workMode ?? WorkMode.ON_SITE;
    employee.skills = [];
    employee.certifications = [];

    const savedEmployee = await this.employeeRepository.save(employee);
    const reloaded = await this.employeeRepository.findById(savedEmployee.id);

    await this.checklistsService.createInstance(
      savedEmployee.id,
      ChecklistType.ONBOARDING,
      reloaded!.workMode,
    );

    return {
      employee: toEmployeeResponse(reloaded!),
      temporaryPassword,
    };
  }

  /** `employees.read` (e.g. Team Lead) only grants a directory-style view —
   * financial and personal-contact fields are stripped unless the viewer
   * also holds `employees.manage`, or is looking at their own record. */
  async findAll(viewer: JwtPayload): Promise<EmployeeResponse[]> {
    const employees = await this.employeeRepository.findAll();
    return employees.map((employee) =>
      this.applyFieldVisibility(toEmployeeResponse(employee), employee, viewer),
    );
  }

  /** Active employees whose birthday falls within the next [withinDays]
   * days, or happened within the last [recentDays] days — so a just-passed
   * birthday still shows up as a "recently happened" notification instead
   * of disappearing until its next occurrence a year away. Employees who
   * are on leave, on notice, resigned, or terminated are excluded — only
   * active employees' birthdays are worth notifying about. */
  async getUpcomingBirthdays(
    withinDays = 7,
    recentDays = 7,
  ): Promise<UpcomingBirthdayResponse[]> {
    const employees = await this.employeeRepository.findAll();
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    return employees
      .filter(
        (employee) =>
          employee.employmentStatus === EmploymentStatus.ACTIVE &&
          employee.dateOfBirth,
      )
      .map((employee) => ({
        employee,
        daysUntil: this.closestAnnualOccurrence(employee.dateOfBirth!, today)
          .daysUntil,
      }))
      .filter(({ daysUntil }) => daysUntil <= withinDays && daysUntil >= -recentDays)
      .sort((a, b) => a.daysUntil - b.daysUntil)
      .map(({ employee, daysUntil }) => ({
        employeeId: employee.id,
        fullName: this.fullName(employee),
        profilePhotoUrl: employee.profilePhotoUrl ?? null,
        dateOfBirth: employee.dateOfBirth!,
        daysUntil,
      }));
  }

  /** Active employees marking a work anniversary (1+ full years of service)
   * within the next [withinDays] days, or within the last [recentDays] days.
   * Mirrors getUpcomingBirthdays, but keyed off joiningDate instead of
   * dateOfBirth, and only counts once a full year of service has passed
   * (an employee's own join date isn't their first "anniversary"). */
  async getUpcomingWorkAnniversaries(
    withinDays = 7,
    recentDays = 7,
  ): Promise<UpcomingWorkAnniversaryResponse[]> {
    const employees = await this.employeeRepository.findAll();
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    return employees
      .filter((employee) => employee.employmentStatus === EmploymentStatus.ACTIVE)
      .map((employee) => {
        const { daysUntil, occurrenceYear } = this.closestAnnualOccurrence(
          employee.joiningDate,
          today,
        );
        const yearsOfService =
          occurrenceYear - new Date(employee.joiningDate).getFullYear();
        return { employee, daysUntil, yearsOfService };
      })
      .filter(
        ({ daysUntil, yearsOfService }) =>
          yearsOfService >= 1 && daysUntil <= withinDays && daysUntil >= -recentDays,
      )
      .sort((a, b) => a.daysUntil - b.daysUntil)
      .map(({ employee, daysUntil, yearsOfService }) => ({
        employeeId: employee.id,
        fullName: this.fullName(employee),
        profilePhotoUrl: employee.profilePhotoUrl ?? null,
        joiningDate: employee.joiningDate,
        daysUntil,
        yearsOfService,
      }));
  }

  /** How the company-wide active-employee count has changed over the last
   * [days] days, for the Admin Dashboard's Overview stats. Reconstructed
   * entirely from data that already exists — no new snapshot table — by
   * combining the current employee list with every "Employment Status"
   * audit-log change recorded since the cutoff: an employee's status "as of
   * the cutoff" is the `oldValue` of the *earliest* such change after the
   * cutoff if one exists, else their current status unchanged; an employee
   * created after the cutoff didn't exist yet, so they count as "not active
   * back then" regardless of their current status (a new hire who's active
   * today correctly shows up as part of the +1, not excluded from both
   * sides). */
  async getActiveEmployeeDelta(days: number): Promise<{ delta: number }> {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - days);

    const [employees, changesSinceCutoff] = await Promise.all([
      this.employeeRepository.findAll(),
      this.auditLogRepository.findFieldChangesSince(
        'Employment Status',
        cutoff,
      ),
    ]);

    const earliestChangeByEmployee = new Map<string, string | null>();
    for (const change of changesSinceCutoff) {
      if (!earliestChangeByEmployee.has(change.employeeId)) {
        earliestChangeByEmployee.set(change.employeeId, change.oldValue);
      }
    }

    const activeNow = employees.filter(
      (e) => e.employmentStatus === EmploymentStatus.ACTIVE,
    ).length;

    const activeAsOfCutoff = employees.filter((e) => {
      if (e.createdAt > cutoff) return false;
      const statusBeforeWindow = earliestChangeByEmployee.get(e.id);
      if (statusBeforeWindow !== undefined) {
        return statusBeforeWindow === EmploymentStatus.ACTIVE;
      }
      return e.employmentStatus === EmploymentStatus.ACTIVE;
    }).length;

    return { delta: activeNow - activeAsOfCutoff };
  }

  /** Days until (or since, if negative) the closest occurrence — last
   * year's, this year's, or next year's — of the month/day encoded in
   * [dateStr], along with the calendar year that occurrence falls in
   * (needed to compute e.g. years of service for anniversaries). */
  private closestAnnualOccurrence(
    dateStr: string,
    today: Date,
  ): { daysUntil: number; occurrenceYear: number } {
    const date = new Date(dateStr);
    const msPerDay = 24 * 60 * 60 * 1000;
    const candidates = [-1, 0, 1].map((yearOffset) => {
      const occurrenceYear = today.getFullYear() + yearOffset;
      const occurrence = new Date(occurrenceYear, date.getMonth(), date.getDate());
      const daysUntil = Math.round(
        (occurrence.getTime() - today.getTime()) / msPerDay,
      );
      return { daysUntil, occurrenceYear };
    });
    return candidates.reduce((closest, candidate) =>
      Math.abs(candidate.daysUntil) < Math.abs(closest.daysUntil) ? candidate : closest,
    );
  }

  /** Sums the current salary (the most recent record by effectiveDate) of
   * every active employee — on-leave/notice-period/resigned/terminated
   * employees don't count, since they aren't currently drawing a salary
   * against the payroll the same way. An employee with no salary records
   * yet simply contributes 0 rather than being excluded. */
  async getPayrollSummary(): Promise<PayrollSummaryResponse> {
    const employees = await this.employeeRepository.findAll();
    const activeEmployees = employees.filter(
      (employee) => employee.employmentStatus === EmploymentStatus.ACTIVE,
    );

    const currentSalaries = await Promise.all(
      activeEmployees.map(async (employee) => {
        const records = await this.salaryRecordRepository.findByEmployeeId(
          employee.id,
        );
        const current = records[records.length - 1];
        return current ? Number(current.amount) : 0;
      }),
    );

    const totalMonthlyPayroll = currentSalaries.reduce(
      (sum, amount) => sum + amount,
      0,
    );
    const now = new Date();
    const daysInMonth = new Date(
      now.getFullYear(),
      now.getMonth() + 1,
      0,
    ).getDate();

    return {
      totalMonthlyPayroll,
      dailyPayroll: totalMonthlyPayroll / daysInMonth,
      activeEmployeeCount: activeEmployees.length,
    };
  }

  /** The salary in effect as of [asOfIsoDate] — the latest record whose
   * `effectiveDate` is on or before it (records are chronological, so this
   * is the last one that qualifies) — 0 if the employee has no salary
   * records yet, or none had taken effect by that date. Plain string
   * comparison is safe here since `effectiveDate` is already 'YYYY-MM-DD'.
   * Used by Payroll to compute a run's baseSalary for a specific month. */
  async getSalaryAsOf(
    employeeId: string,
    asOfIsoDate: string,
  ): Promise<number> {
    const records = await this.salaryRecordRepository.findByEmployeeId(
      employeeId,
    );
    const eligible = records.filter(
      (record) => record.effectiveDate <= asOfIsoDate,
    );
    const latest = eligible[eligible.length - 1];
    return latest ? Number(latest.amount) : 0;
  }

  async findById(id: string, viewer: JwtPayload): Promise<EmployeeResponse> {
    const employee = await this.employeeRepository.findById(id);
    if (!employee) throw new NotFoundException('Employee not found');
    return this.applyFieldVisibility(toEmployeeResponse(employee), employee, viewer);
  }

  /** Financial/personal-contact fields are only visible to `employees.manage`
   * holders or to the employee themselves — not to a plain `employees.read`
   * viewer (e.g. Team Lead), who only needs directory-level fields.
   * [revealBirthday] is set by `getMyDirectReports` — a reporting manager
   * seeing their own reports' birthdays (for the "My Team" dashboard
   * section) is a much narrower exposure than the company-wide directory
   * `dateOfBirth: null` guards against, since the caller is already scoped
   * to just that manager's own reports. */
  private applyFieldVisibility(
    response: EmployeeResponse,
    employee: Employee,
    viewer: JwtPayload,
    options?: { revealBirthday?: boolean },
  ): EmployeeResponse {
    const isSelf = employee.userId === viewer.sub;
    const canManage = viewer.permissions.includes('employees.manage');
    if (isSelf || canManage) return response;

    return {
      ...response,
      dateOfBirth: options?.revealBirthday ? response.dateOfBirth : null,
      personalEmail: null,
      phoneNumber: null,
      emergencyContactName: null,
      emergencyContactPhone: null,
      emergencyContactRelation: null,
      address: null,
      bankName: null,
      accountTitle: null,
      accountNumber: null,
      branchCode: null,
      iban: null,
    };
  }

  async findByUserId(userId: string): Promise<EmployeeResponse> {
    const employee = await this.employeeRepository.findByUserId(userId);
    if (!employee) throw new NotFoundException('Employee profile not found');
    return toEmployeeResponse(employee);
  }

  async getMyDirectReports(viewer: JwtPayload): Promise<EmployeeResponse[]> {
    const employee = await this.employeeRepository.findByUserId(viewer.sub);
    if (!employee) throw new NotFoundException('Employee profile not found');
    const reports = await this.employeeRepository.findByReportingManagerId(
      employee.id,
    );
    return reports.map((report) =>
      this.applyFieldVisibility(toEmployeeResponse(report), report, viewer, {
        revealBirthday: true,
      }),
    );
  }

  async updateSelf(
    userId: string,
    dto: UpdateMyProfileDto,
  ): Promise<EmployeeResponse> {
    const employee = await this.employeeRepository.findByUserId(userId);
    if (!employee) throw new NotFoundException('Employee profile not found');

    const before = { ...employee };
    Object.assign(employee, definedFieldsOnly(dto));
    const saved = await this.employeeRepository.save(employee);
    const reloaded = await this.employeeRepository.findById(saved.id);

    const diffs = await this.buildFieldDiffs(before, reloaded!);
    await this.recordAuditEntries(
      saved.id,
      {
        userId,
        name: this.fullName(before),
      },
      diffs,
    );

    return toEmployeeResponse(reloaded!);
  }

  /** The field-level diffs an [UpdateMyProfileDto] would produce, without
   * saving anything — used to show a requester and their approver what a
   * pending profile-change request actually contains. */
  async previewProfileChanges(
    employeeId: string,
    dto: UpdateMyProfileDto,
  ): Promise<FieldDiff[]> {
    const employee = await this.employeeRepository.findById(employeeId);
    if (!employee) throw new NotFoundException('Employee not found');

    const after: EmployeeSnapshot = { ...employee, ...definedFieldsOnly(dto) };
    return this.buildFieldDiffs(employee, after);
  }

  /** Applies an approved profile-change request's payload directly to the
   * employee record, with the same diff/audit trail as a self-service edit. */
  async applyApprovedProfileChange(
    employeeId: string,
    dto: UpdateMyProfileDto,
  ): Promise<void> {
    const employee = await this.employeeRepository.findById(employeeId);
    if (!employee) throw new NotFoundException('Employee not found');

    const before = { ...employee };
    Object.assign(employee, definedFieldsOnly(dto));
    const saved = await this.employeeRepository.save(employee);
    const reloaded = await this.employeeRepository.findById(saved.id);

    const diffs = await this.buildFieldDiffs(before, reloaded!);
    await this.recordAuditEntries(
      saved.id,
      { userId: employee.userId, name: this.fullName(before) },
      diffs,
    );
  }

  async updateMyPhoto(
    userId: string,
    file: Express.Multer.File,
  ): Promise<EmployeeResponse> {
    const employee = await this.employeeRepository.findByUserId(userId);
    if (!employee) throw new NotFoundException('Employee profile not found');
    return this.applyPhoto(employee, file);
  }

  /** HR/Admin uploading a photo for someone else's record. */
  async updatePhoto(
    employeeId: string,
    file: Express.Multer.File,
  ): Promise<EmployeeResponse> {
    const employee = await this.employeeRepository.findById(employeeId);
    if (!employee) throw new NotFoundException('Employee not found');
    return this.applyPhoto(employee, file);
  }

  private async applyPhoto(
    employee: Employee,
    file: Express.Multer.File,
  ): Promise<EmployeeResponse> {
    const previousPhotoUrl = employee.profilePhotoUrl;
    employee.profilePhotoUrl = `/uploads/avatars/${file.filename}`;
    const saved = await this.employeeRepository.save(employee);

    if (previousPhotoUrl) {
      await fs
        .unlink(join(process.cwd(), previousPhotoUrl))
        .catch(() => undefined);
    }

    const reloaded = await this.employeeRepository.findById(saved.id);
    return toEmployeeResponse(reloaded!);
  }

  async update(
    id: string,
    dto: UpdateEmployeeDto,
    actorUserId: string,
  ): Promise<EmployeeResponse> {
    const employee = await this.employeeRepository.findById(id);
    if (!employee) throw new NotFoundException('Employee not found');

    const before = { ...employee };
    const previousEmail = employee.user.email;
    const { companyEmail, ...employeeFields } = dto;
    Object.assign(employee, definedFieldsOnly(employeeFields));
    const saved = await this.employeeRepository.save(employee);

    const emailChanged = !!companyEmail && companyEmail !== previousEmail;
    if (emailChanged) {
      const existingUser = await this.userRepository.findByEmail(
        companyEmail,
      );
      if (existingUser && existingUser.id !== employee.userId) {
        throw new ConflictException('A user with this email already exists');
      }
      const user = await this.userRepository.findById(employee.userId);
      user!.email = companyEmail;
      await this.userRepository.save(user!);
    }

    const reloaded = await this.employeeRepository.findById(saved.id);

    const diffs = await this.buildFieldDiffs(before, reloaded!);
    if (emailChanged) {
      diffs.push({
        fieldLabel: 'Company Email',
        oldValue: previousEmail,
        newValue: companyEmail,
      });
    }
    const actorName = await this.resolveActorName(actorUserId);
    await this.recordAuditEntries(
      saved.id,
      { userId: actorUserId, name: actorName },
      diffs,
    );

    // The first time an employee moves from a currently-working status into
    // a leaving one, kick off their offboarding checklist. createInstance is
    // idempotent, so a later transition (e.g. notice_period -> resigned)
    // won't duplicate it — but this condition also just skips those calls
    // outright, since `before.employmentStatus` is no longer a working status.
    const wasWorking =
      before.employmentStatus === EmploymentStatus.ACTIVE ||
      before.employmentStatus === EmploymentStatus.ON_LEAVE;
    const isNowLeaving =
      reloaded!.employmentStatus === EmploymentStatus.NOTICE_PERIOD ||
      reloaded!.employmentStatus === EmploymentStatus.RESIGNED ||
      reloaded!.employmentStatus === EmploymentStatus.TERMINATED;
    if (wasWorking && isNowLeaving) {
      await this.checklistsService.createInstance(
        reloaded!.id,
        ChecklistType.OFFBOARDING,
        reloaded!.workMode,
      );
    }

    return toEmployeeResponse(reloaded!);
  }

  async getAuditLog(employeeId: string): Promise<AuditLogResponse[]> {
    await this.ensureEmployeeExists(employeeId);
    const entries = await this.auditLogRepository.findByEmployeeId(employeeId);
    return entries.map(toAuditLogResponse);
  }

  async getMyAuditLog(userId: string): Promise<AuditLogResponse[]> {
    const employee = await this.employeeRepository.findByUserId(userId);
    if (!employee) throw new NotFoundException('Employee profile not found');
    return this.getAuditLog(employee.id);
  }

  async getCompanyAuditLog(
    query: CompanyAuditLogQueryDto,
  ): Promise<PaginatedAuditLogResponse> {
    const page = query.page ?? 1;
    const limit = query.limit ?? COMPANY_AUDIT_LOG_DEFAULT_LIMIT;
    const { items, total } = await this.auditLogRepository.findAllPaginated({
      page,
      limit,
      search: query.search?.trim() || undefined,
    });
    return { items: items.map(toAuditLogResponse), total, page, limit };
  }

  async listMyDocuments(userId: string): Promise<DocumentResponse[]> {
    const employee = await this.employeeRepository.findByUserId(userId);
    if (!employee) throw new NotFoundException('Employee profile not found');
    return this.listDocuments(employee.id);
  }

  async listDocuments(employeeId: string): Promise<DocumentResponse[]> {
    await this.ensureEmployeeExists(employeeId);
    const documents =
      await this.documentRepository.findByEmployeeId(employeeId);
    return documents.map(toDocumentResponse);
  }

  async uploadMyDocument(
    userId: string,
    file: Express.Multer.File,
    documentType?: DocumentType,
  ): Promise<DocumentResponse> {
    const employee = await this.employeeRepository.findByUserId(userId);
    if (!employee) throw new NotFoundException('Employee profile not found');
    return this.uploadDocument(employee.id, file, userId, documentType);
  }

  async uploadDocument(
    employeeId: string,
    file: Express.Multer.File,
    actorUserId: string,
    documentType?: DocumentType,
  ): Promise<DocumentResponse> {
    await this.ensureEmployeeExists(employeeId);

    const type = documentType ?? DocumentType.OTHER;
    const document = new EmployeeDocument();
    document.employeeId = employeeId;
    document.documentType = type;
    document.fileName = file.originalname;
    document.filePath = `/uploads/documents/${file.filename}`;
    document.fileSize = file.size;

    const saved = await this.documentRepository.save(document);

    const actorName = await this.resolveActorName(actorUserId);
    await this.recordAuditEntries(
      employeeId,
      { userId: actorUserId, name: actorName },
      [
        {
          fieldLabel: DOCUMENT_TYPE_LABELS[type],
          oldValue: null,
          newValue: `Uploaded ${file.originalname}`,
        },
      ],
    );

    return toDocumentResponse(saved);
  }

  async deleteMyDocument(userId: string, documentId: string): Promise<void> {
    const employee = await this.employeeRepository.findByUserId(userId);
    if (!employee) throw new NotFoundException('Employee profile not found');
    return this.deleteDocument(employee.id, documentId, userId);
  }

  async deleteDocument(
    employeeId: string,
    documentId: string,
    actorUserId: string,
  ): Promise<void> {
    const document = await this.documentRepository.findById(documentId);
    if (!document || document.employeeId !== employeeId) {
      throw new NotFoundException('Document not found');
    }

    await this.documentRepository.remove(document);
    await fs
      .unlink(join(process.cwd(), document.filePath))
      .catch(() => undefined);

    const actorName = await this.resolveActorName(actorUserId);
    await this.recordAuditEntries(
      employeeId,
      { userId: actorUserId, name: actorName },
      [
        {
          fieldLabel: DOCUMENT_TYPE_LABELS[document.documentType],
          oldValue: `Removed ${document.fileName}`,
          newValue: null,
        },
      ],
    );
  }

  async getSalaryHistory(employeeId: string): Promise<SalaryRecordResponse[]> {
    await this.ensureEmployeeExists(employeeId);
    const records =
      await this.salaryRecordRepository.findByEmployeeId(employeeId);
    return records.map(toSalaryRecordResponse);
  }

  async getMySalaryHistory(userId: string): Promise<SalaryRecordResponse[]> {
    const employee = await this.employeeRepository.findByUserId(userId);
    if (!employee) throw new NotFoundException('Employee profile not found');
    return this.getSalaryHistory(employee.id);
  }

  async getEmployeeChecklist(
    employeeId: string,
    type: ChecklistType,
  ): Promise<EmployeeChecklistItem[]> {
    await this.ensureEmployeeExists(employeeId);
    return this.checklistsService.getEmployeeChecklist(employeeId, type);
  }

  async getMyChecklist(
    userId: string,
    type: ChecklistType,
  ): Promise<EmployeeChecklistItem[]> {
    const employee = await this.employeeRepository.findByUserId(userId);
    if (!employee) throw new NotFoundException('Employee profile not found');
    return this.checklistsService.getEmployeeChecklist(employee.id, type);
  }

  async setChecklistItemCompleted(
    itemId: string,
    dto: SetChecklistItemCompletedDto,
    actorUserId: string,
  ): Promise<EmployeeChecklistItem> {
    const actorName = await this.resolveActorName(actorUserId);
    return this.checklistsService.setItemCompleted(
      itemId,
      dto,
      actorUserId,
      actorName,
    );
  }

  async addSalaryRecord(
    employeeId: string,
    dto: AddSalaryRecordDto,
    actorUserId: string,
  ): Promise<SalaryRecordResponse> {
    await this.ensureEmployeeExists(employeeId);
    const existing =
      await this.salaryRecordRepository.findByEmployeeId(employeeId);
    const previous = existing[existing.length - 1] ?? null;

    const record = new SalaryRecord();
    record.employeeId = employeeId;
    record.amount = dto.amount.toFixed(2);
    record.effectiveDate = dto.effectiveDate;
    record.note = dto.note;

    const saved = await this.salaryRecordRepository.save(record);

    const actorName = await this.resolveActorName(actorUserId);
    await this.recordAuditEntries(
      employeeId,
      { userId: actorUserId, name: actorName },
      [
        {
          fieldLabel: 'Salary',
          oldValue: previous ? this.formatAmount(previous.amount) : null,
          newValue: this.formatAmount(saved.amount),
        },
      ],
    );

    return toSalaryRecordResponse(saved);
  }

  async deleteSalaryRecord(
    employeeId: string,
    recordId: string,
    actorUserId: string,
  ): Promise<void> {
    const record = await this.salaryRecordRepository.findById(recordId);
    if (!record || record.employeeId !== employeeId) {
      throw new NotFoundException('Salary record not found');
    }

    await this.salaryRecordRepository.remove(record);

    const actorName = await this.resolveActorName(actorUserId);
    await this.recordAuditEntries(
      employeeId,
      { userId: actorUserId, name: actorName },
      [
        {
          fieldLabel: 'Salary',
          oldValue: `Removed record of ${this.formatAmount(record.amount)}`,
          newValue: null,
        },
      ],
    );
  }

  async getMyEducationHistory(
    userId: string,
  ): Promise<EducationRecordResponse[]> {
    const employee = await this.employeeRepository.findByUserId(userId);
    if (!employee) throw new NotFoundException('Employee profile not found');
    return this.getEducationHistory(employee.id);
  }

  async getEducationHistory(
    employeeId: string,
  ): Promise<EducationRecordResponse[]> {
    await this.ensureEmployeeExists(employeeId);
    const records =
      await this.educationRecordRepository.findByEmployeeId(employeeId);
    return records.map(toEducationRecordResponse);
  }

  async addMyEducationRecord(
    userId: string,
    dto: AddEducationRecordDto,
  ): Promise<EducationRecordResponse> {
    const employee = await this.employeeRepository.findByUserId(userId);
    if (!employee) throw new NotFoundException('Employee profile not found');
    return this.addEducationRecord(employee.id, dto, userId);
  }

  async addEducationRecord(
    employeeId: string,
    dto: AddEducationRecordDto,
    actorUserId: string,
  ): Promise<EducationRecordResponse> {
    await this.ensureEmployeeExists(employeeId);

    const record = new EducationRecord();
    record.employeeId = employeeId;
    record.degree = dto.degree;
    record.institution = dto.institution;
    record.yearCompleted = dto.yearCompleted;

    const saved = await this.educationRecordRepository.save(record);

    const actorName = await this.resolveActorName(actorUserId);
    await this.recordAuditEntries(
      employeeId,
      { userId: actorUserId, name: actorName },
      [
        {
          fieldLabel: 'Education',
          oldValue: null,
          newValue: `${saved.degree}, ${saved.institution} (${saved.yearCompleted})`,
        },
      ],
    );

    return toEducationRecordResponse(saved);
  }

  async deleteMyEducationRecord(
    userId: string,
    recordId: string,
  ): Promise<void> {
    const employee = await this.employeeRepository.findByUserId(userId);
    if (!employee) throw new NotFoundException('Employee profile not found');
    return this.deleteEducationRecord(employee.id, recordId, userId);
  }

  async deleteEducationRecord(
    employeeId: string,
    recordId: string,
    actorUserId: string,
  ): Promise<void> {
    const record = await this.educationRecordRepository.findById(recordId);
    if (!record || record.employeeId !== employeeId) {
      throw new NotFoundException('Education record not found');
    }

    await this.educationRecordRepository.remove(record);

    const actorName = await this.resolveActorName(actorUserId);
    await this.recordAuditEntries(
      employeeId,
      { userId: actorUserId, name: actorName },
      [
        {
          fieldLabel: 'Education',
          oldValue: `Removed ${record.degree}, ${record.institution} (${record.yearCompleted})`,
          newValue: null,
        },
      ],
    );
  }

  async getMyAssets(userId: string): Promise<AssetResponse[]> {
    const employee = await this.employeeRepository.findByUserId(userId);
    if (!employee) throw new NotFoundException('Employee profile not found');
    return this.getAssets(employee.id);
  }

  async getAssets(employeeId: string): Promise<AssetResponse[]> {
    await this.ensureEmployeeExists(employeeId);
    const assets =
      await this.assetRepository.findByAssignedEmployeeId(employeeId);
    return assets.map(toAssetResponse);
  }

  async createAndAssignAsset(
    employeeId: string,
    dto: CreateAssetDto,
    actorUserId: string,
  ): Promise<AssetResponse> {
    await this.ensureEmployeeExists(employeeId);

    const asset = new Asset();
    asset.name = dto.name;
    asset.value = dto.value?.toFixed(2);
    asset.status = AssetStatus.ASSIGNED;
    asset.assignedEmployeeId = employeeId;
    asset.assignedAt = new Date();

    const saved = await this.assetRepository.save(asset);

    const actorName = await this.resolveActorName(actorUserId);
    await this.recordAuditEntries(
      employeeId,
      { userId: actorUserId, name: actorName },
      [{ fieldLabel: 'Assets', oldValue: null, newValue: `Assigned ${saved.name}` }],
    );

    return toAssetResponse(saved);
  }

  async updateAsset(
    employeeId: string,
    assetId: string,
    dto: UpdateAssetDto,
  ): Promise<AssetResponse> {
    const asset = await this.loadAssignedAsset(employeeId, assetId);
    if (dto.name !== undefined) asset.name = dto.name;
    if (dto.value !== undefined) asset.value = dto.value.toFixed(2);
    const saved = await this.assetRepository.save(asset);
    return toAssetResponse(saved);
  }

  async deleteAsset(
    employeeId: string,
    assetId: string,
    actorUserId: string,
  ): Promise<void> {
    const asset = await this.loadAssignedAsset(employeeId, assetId);
    const assetName = asset.name;
    await this.assetRepository.remove(asset);

    const actorName = await this.resolveActorName(actorUserId);
    await this.recordAuditEntries(
      employeeId,
      { userId: actorUserId, name: actorName },
      [{ fieldLabel: 'Assets', oldValue: `Assigned ${assetName}`, newValue: null }],
    );
  }

  private async loadAssignedAsset(
    employeeId: string,
    assetId: string,
  ): Promise<Asset> {
    const asset = await this.assetRepository.findById(assetId);
    if (!asset || asset.assignedEmployeeId !== employeeId) {
      throw new NotFoundException('Asset not found');
    }
    return asset;
  }

  private formatAmount(amount: string): string {
    const value = Number(amount);
    if (Number.isNaN(value)) return amount;
    return value.toLocaleString(undefined, {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    });
  }

  private async ensureEmployeeExists(employeeId: string): Promise<void> {
    const employee = await this.employeeRepository.findById(employeeId);
    if (!employee) throw new NotFoundException('Employee not found');
  }

  private async generateEmployeeCode(): Promise<string> {
    const count = await this.employeeRepository.count();
    return `ZC-${String(count + 1).padStart(5, '0')}`;
  }

  private fullName(employee: Pick<Employee, 'firstName' | 'lastName'>): string {
    return `${employee.firstName} ${employee.lastName}`.trim();
  }

  private resolveActorName(actorUserId: string): Promise<string> {
    return resolveActorName(
      this.employeeRepository,
      this.userRepository,
      actorUserId,
    );
  }

  private async recordAuditEntries(
    employeeId: string,
    actor: { userId: string; name: string },
    diffs: FieldDiff[],
  ): Promise<void> {
    if (diffs.length === 0) return;
    const entries = diffs.map((diff) => {
      const entry = new EmployeeAuditLog();
      entry.employeeId = employeeId;
      entry.actorUserId = actor.userId;
      entry.actorName = actor.name;
      entry.fieldLabel = diff.fieldLabel;
      entry.oldValue = diff.oldValue;
      entry.newValue = diff.newValue;
      return entry;
    });
    await this.auditLogRepository.saveMany(entries);
  }

  private async buildFieldDiffs(
    before: EmployeeSnapshot,
    after: EmployeeSnapshot,
  ): Promise<FieldDiff[]> {
    const diffs: FieldDiff[] = [];
    const addIfChanged = (
      fieldLabel: string,
      oldValue: string | null,
      newValue: string | null,
    ) => {
      if (oldValue === newValue) return;
      diffs.push({ fieldLabel, oldValue, newValue });
    };

    addIfChanged('First Name', before.firstName, after.firstName);
    addIfChanged('Last Name', before.lastName, after.lastName);
    addIfChanged(
      'Designation',
      before.designation ?? null,
      after.designation ?? null,
    );
    addIfChanged(
      'Department',
      before.department?.name ?? null,
      after.department?.name ?? null,
    );
    addIfChanged(
      'Employment Type',
      before.employmentType,
      after.employmentType,
    );
    addIfChanged(
      'Employment Status',
      before.employmentStatus,
      after.employmentStatus,
    );
    addIfChanged('Work Mode', before.workMode, after.workMode);
    addIfChanged('Joining Date', before.joiningDate, after.joiningDate);
    addIfChanged(
      'Date of Leaving',
      before.dateOfLeaving ?? null,
      after.dateOfLeaving ?? null,
    );
    addIfChanged(
      'Date of Birth',
      before.dateOfBirth ?? null,
      after.dateOfBirth ?? null,
    );
    addIfChanged(
      'Personal Email',
      before.personalEmail ?? null,
      after.personalEmail ?? null,
    );
    addIfChanged(
      'Phone Number',
      before.phoneNumber ?? null,
      after.phoneNumber ?? null,
    );
    addIfChanged(
      'Emergency Contact Name',
      before.emergencyContactName ?? null,
      after.emergencyContactName ?? null,
    );
    addIfChanged(
      'Emergency Contact Phone',
      before.emergencyContactPhone ?? null,
      after.emergencyContactPhone ?? null,
    );
    addIfChanged(
      'Emergency Contact Relation',
      before.emergencyContactRelation ?? null,
      after.emergencyContactRelation ?? null,
    );
    addIfChanged('Address', before.address ?? null, after.address ?? null);
    addIfChanged('Bank Name', before.bankName ?? null, after.bankName ?? null);
    addIfChanged(
      'Account Title',
      before.accountTitle ?? null,
      after.accountTitle ?? null,
    );
    addIfChanged(
      'Account Number',
      before.accountNumber ?? null,
      after.accountNumber ?? null,
    );
    addIfChanged(
      'Branch Code',
      before.branchCode ?? null,
      after.branchCode ?? null,
    );
    addIfChanged('IBAN', before.iban ?? null, after.iban ?? null);
    addIfChanged(
      'Skills',
      before.skills.join(', ') || null,
      after.skills.join(', ') || null,
    );
    addIfChanged(
      'Certifications',
      before.certifications.join(', ') || null,
      after.certifications.join(', ') || null,
    );
    addIfChanged(
      'Profile Photo',
      before.profilePhotoUrl ?? null,
      after.profilePhotoUrl ?? null,
    );

    if (before.reportingManagerId !== after.reportingManagerId) {
      const [oldManager, newManager] = await Promise.all([
        before.reportingManagerId
          ? this.employeeRepository.findById(before.reportingManagerId)
          : Promise.resolve(null),
        after.reportingManagerId
          ? this.employeeRepository.findById(after.reportingManagerId)
          : Promise.resolve(null),
      ]);
      addIfChanged(
        'Reporting Manager',
        oldManager ? this.fullName(oldManager) : null,
        newManager ? this.fullName(newManager) : null,
      );
    }

    return diffs;
  }
}
