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
import { User } from '../../authentication/domain/entities/user.entity';
import { UserStatus } from '../../authentication/domain/enums/user-status.enum';
import {
  ROLE_REPOSITORY,
  type RoleRepository,
} from '../../authentication/domain/repositories/role-repository.interface';
import {
  USER_REPOSITORY,
  type UserRepository,
} from '../../authentication/domain/repositories/user-repository.interface';
import { Employee } from '../domain/entities/employee.entity';
import { EmployeeAuditLog } from '../domain/entities/employee-audit-log.entity';
import { EmployeeDocument } from '../domain/entities/employee-document.entity';
import { EducationRecord } from '../domain/entities/education-record.entity';
import { SalaryRecord } from '../domain/entities/salary-record.entity';
import { DocumentType } from '../domain/enums/document-type.enum';
import {
  EMPLOYEE_REPOSITORY,
  type EmployeeRepository,
} from '../domain/repositories/employee-repository.interface';
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
import { AuditLogResponse } from './audit-log-response.interface';
import { toAuditLogResponse } from './audit-log.mapper';
import { DocumentResponse } from './document-response.interface';
import { toDocumentResponse } from './document.mapper';
import { EmployeeResponse } from './employee-response.interface';
import { toEmployeeResponse } from './employee.mapper';
import { generateTemporaryPassword } from './generate-temporary-password.util';
import { AddEducationRecordDto } from './dto/add-education-record.dto';
import { AddSalaryRecordDto } from './dto/add-salary-record.dto';
import { InviteEmployeeDto } from './dto/invite-employee.dto';
import { UpdateEmployeeDto } from './dto/update-employee.dto';
import { UpdateMyProfileDto } from './dto/update-my-profile.dto';
import { EducationRecordResponse } from './education-record-response.interface';
import { toEducationRecordResponse } from './education-record.mapper';
import { SalaryRecordResponse } from './salary-record-response.interface';
import { toSalaryRecordResponse } from './salary-record.mapper';

const DEFAULT_INVITE_ROLE = 'Employee';
const COMPANY_AUDIT_LOG_LIMIT = 100;

const DOCUMENT_TYPE_LABELS: Record<DocumentType, string> = {
  [DocumentType.CONTRACT]: 'Contract',
  [DocumentType.RESUME]: 'Resume',
  [DocumentType.CNIC]: 'CNIC / National ID',
  [DocumentType.OTHER]: 'Document',
};

interface FieldDiff {
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
  | 'team'
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
    employee.employeeCode = await this.generateEmployeeCode();
    employee.firstName = dto.firstName;
    employee.lastName = dto.lastName;
    employee.designation = dto.designation;
    employee.departmentId = dto.departmentId;
    employee.teamId = dto.teamId;
    employee.reportingManagerId = dto.reportingManagerId;
    employee.joiningDate =
      dto.joiningDate ?? new Date().toISOString().slice(0, 10);
    employee.skills = [];
    employee.certifications = [];

    const savedEmployee = await this.employeeRepository.save(employee);
    const reloaded = await this.employeeRepository.findById(savedEmployee.id);

    return {
      employee: toEmployeeResponse(reloaded!),
      temporaryPassword,
    };
  }

  async findAll(): Promise<EmployeeResponse[]> {
    const employees = await this.employeeRepository.findAll();
    return employees.map(toEmployeeResponse);
  }

  async findById(id: string): Promise<EmployeeResponse> {
    const employee = await this.employeeRepository.findById(id);
    if (!employee) throw new NotFoundException('Employee not found');
    return toEmployeeResponse(employee);
  }

  async findByUserId(userId: string): Promise<EmployeeResponse> {
    const employee = await this.employeeRepository.findByUserId(userId);
    if (!employee) throw new NotFoundException('Employee profile not found');
    return toEmployeeResponse(employee);
  }

  async updateSelf(
    userId: string,
    dto: UpdateMyProfileDto,
  ): Promise<EmployeeResponse> {
    const employee = await this.employeeRepository.findByUserId(userId);
    if (!employee) throw new NotFoundException('Employee profile not found');

    const before = { ...employee };
    Object.assign(employee, dto);
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

  async updateMyPhoto(
    userId: string,
    file: Express.Multer.File,
  ): Promise<EmployeeResponse> {
    const employee = await this.employeeRepository.findByUserId(userId);
    if (!employee) throw new NotFoundException('Employee profile not found');

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
    Object.assign(employee, dto);
    const saved = await this.employeeRepository.save(employee);
    const reloaded = await this.employeeRepository.findById(saved.id);

    const diffs = await this.buildFieldDiffs(before, reloaded!);
    const actorName = await this.resolveActorName(actorUserId);
    await this.recordAuditEntries(
      saved.id,
      { userId: actorUserId, name: actorName },
      diffs,
    );

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

  async getCompanyAuditLog(): Promise<AuditLogResponse[]> {
    const entries = await this.auditLogRepository.findAll(
      COMPANY_AUDIT_LOG_LIMIT,
    );
    return entries.map(toAuditLogResponse);
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

  private async resolveActorName(actorUserId: string): Promise<string> {
    const actorEmployee =
      await this.employeeRepository.findByUserId(actorUserId);
    if (actorEmployee) return this.fullName(actorEmployee);
    const user = await this.userRepository.findById(actorUserId);
    return user?.email ?? 'Unknown';
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
    addIfChanged('Team', before.team?.name ?? null, after.team?.name ?? null);
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
