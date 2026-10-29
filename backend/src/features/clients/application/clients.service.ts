import {
  BadRequestException,
  Injectable,
  Inject,
  NotFoundException,
} from '@nestjs/common';
import { definedFieldsOnly } from '../../../core/utils/defined-fields-only.util';
import { resolveActorName } from '../../../core/utils/resolve-actor-name.util';
import {
  USER_REPOSITORY,
  type UserRepository,
} from '../../authentication/domain/repositories/user-repository.interface';
import {
  DEPARTMENT_REPOSITORY,
  type DepartmentRepository,
} from '../../departments/domain/repositories/department-repository.interface';
import { Employee } from '../../employee/domain/entities/employee.entity';
import {
  EMPLOYEE_REPOSITORY,
  type EmployeeRepository,
} from '../../employee/domain/repositories/employee-repository.interface';
import { Department } from '../../departments/domain/entities/department.entity';
import { CreateClientDto } from './dto/create-client.dto';
import { CreateProjectDto } from './dto/create-project.dto';
import { CreateServiceDto } from './dto/create-service.dto';
import { UpdateClientDto } from './dto/update-client.dto';
import { UpdateClientHealthDto } from './dto/update-client-health.dto';
import { UpdateProjectDto } from './dto/update-project.dto';
import { UpdateServiceDto } from './dto/update-service.dto';
import { Client } from '../domain/entities/client.entity';
import { ClientHealthHistory } from '../domain/entities/client-health-history.entity';
import { Project } from '../domain/entities/project.entity';
import { Service } from '../domain/entities/service.entity';
import { ClientHealthStatus } from '../domain/enums/client-health-status.enum';
import { ProjectStatus } from '../domain/enums/project-status.enum';
import { ProjectType } from '../domain/enums/project-type.enum';
import { Cron, CronExpression } from '@nestjs/schedule';
import { NotificationsService } from '../../notifications/application/notifications.service';
import { NotificationLinkTarget } from '../../notifications/domain/enums/notification-link-target.enum';
import {
  CLIENT_REPOSITORY,
  type ClientRepository,
} from '../domain/repositories/client-repository.interface';
import {
  CLIENT_HEALTH_HISTORY_REPOSITORY,
  type ClientHealthHistoryRepository,
} from '../domain/repositories/client-health-history-repository.interface';
import {
  PROJECT_REPOSITORY,
  type ProjectRepository,
} from '../domain/repositories/project-repository.interface';
import {
  SERVICE_REPOSITORY,
  type ServiceRepository,
} from '../domain/repositories/service-repository.interface';
import {
  ClientHealthHistoryResponseDto,
  ClientHealthSummaryDto,
  ClientResponseDto,
  ProjectResponseDto,
  ProjectsSummaryDto,
  ServiceResponseDto,
} from './client-response.interface';
import {
  toClientHealthHistoryResponse,
  toClientResponse,
  toProjectResponse,
  toServiceResponse,
} from './client.mapper';

/** Days before a retainer's renewal on which its owners get a reminder. */
const RENEWAL_REMINDER_DAYS = [30, 14, 7];

const HEALTH_LABELS: Record<string, string> = {
  healthy: 'Healthy',
  attention_required: 'Attention Required',
  at_risk: 'At Risk',
};

function formatHealth(status: string): string {
  return HEALTH_LABELS[status] ?? status;
}

/** Today's date (YYYY-MM-DD) in Pakistan time, UTC+5, like the rest of the
 * app's date handling. */
function pakistanToday(): string {
  return new Date(Date.now() + 5 * 60 * 60 * 1000).toISOString().slice(0, 10);
}

function daysBetween(from: string, to: string): number {
  return Math.round(
    (new Date(`${to}T00:00:00Z`).getTime() -
      new Date(`${from}T00:00:00Z`).getTime()) /
      86_400_000,
  );
}

@Injectable()
export class ClientsService {
  constructor(
    @Inject(CLIENT_REPOSITORY)
    private readonly clientRepository: ClientRepository,
    @Inject(SERVICE_REPOSITORY)
    private readonly serviceRepository: ServiceRepository,
    @Inject(PROJECT_REPOSITORY)
    private readonly projectRepository: ProjectRepository,
    @Inject(EMPLOYEE_REPOSITORY)
    private readonly employeeRepository: EmployeeRepository,
    @Inject(DEPARTMENT_REPOSITORY)
    private readonly departmentRepository: DepartmentRepository,
    @Inject(CLIENT_HEALTH_HISTORY_REPOSITORY)
    private readonly clientHealthHistoryRepository: ClientHealthHistoryRepository,
    @Inject(USER_REPOSITORY)
    private readonly userRepository: UserRepository,
    private readonly notificationsService: NotificationsService,
  ) {}

  // ---- Clients ----

  async getClients(includeArchived: boolean): Promise<ClientResponseDto[]> {
    const clients = await this.clientRepository.findAll(includeArchived);
    return clients.map(toClientResponse);
  }

  async getClient(id: string): Promise<ClientResponseDto> {
    return toClientResponse(await this.getClientOrThrow(id));
  }

  async createClient(dto: CreateClientDto): Promise<ClientResponseDto> {
    const client = new Client();
    client.companyName = dto.companyName;
    client.industry = dto.industry;
    client.website = dto.website;
    client.country = dto.country;
    client.address = dto.address;
    client.primaryContactName = dto.primaryContactName;
    client.primaryContactEmail = dto.primaryContactEmail;
    client.primaryContactPhone = dto.primaryContactPhone;
    client.leadSource = dto.leadSource;
    client.notes = dto.notes;
    await this.applyClientAccountManager(client, dto.accountManagerId);
    client.isArchived = false;
    client.archivedAt = null;
    client.healthStatus = ClientHealthStatus.HEALTHY;
    client.healthFactors = [];

    const saved = await this.clientRepository.save(client);
    return toClientResponse(saved);
  }

  async updateClient(
    id: string,
    dto: UpdateClientDto,
  ): Promise<ClientResponseDto> {
    const client = await this.getClientOrThrow(id);
    const changes = definedFieldsOnly(dto);
    if (
      changes.isArchived !== undefined &&
      changes.isArchived !== client.isArchived
    ) {
      client.archivedAt = changes.isArchived ? new Date() : null;
    }
    const { accountManagerId, ...rest } = changes;
    Object.assign(client, rest);
    if (accountManagerId !== undefined) {
      await this.applyClientAccountManager(client, accountManagerId);
    }
    const saved = await this.clientRepository.save(client);
    return toClientResponse(saved);
  }

  /** Sets the client's account manager (an employee); an empty/undefined id
   * clears it. */
  private async applyClientAccountManager(
    client: Client,
    accountManagerId: string | undefined,
  ): Promise<void> {
    if (!accountManagerId) {
      client.accountManager = null;
      client.accountManagerId = null;
      return;
    }
    const manager = await this.employeeRepository.findById(accountManagerId);
    if (!manager) {
      throw new BadRequestException('Account manager not found');
    }
    client.accountManager = manager;
    client.accountManagerId = manager.id;
  }

  private async getClientOrThrow(id: string): Promise<Client> {
    const client = await this.clientRepository.findById(id);
    if (!client) throw new NotFoundException('Client not found');
    return client;
  }

  // ---- Client Health ----

  async updateClientHealth(
    id: string,
    actorUserId: string,
    dto: UpdateClientHealthDto,
  ): Promise<ClientResponseDto> {
    const client = await this.getClientOrThrow(id);
    const previousStatus = client.healthStatus;

    client.healthStatus = dto.status;
    client.healthFactors = dto.factors ?? [];
    client.healthNotes = dto.notes;
    const saved = await this.clientRepository.save(client);

    const actorName = await resolveActorName(
      this.employeeRepository,
      this.userRepository,
      actorUserId,
    );
    const history = new ClientHealthHistory();
    history.clientId = id;
    history.previousStatus = previousStatus;
    history.newStatus = dto.status;
    history.factors = dto.factors ?? [];
    history.notes = dto.notes ?? null;
    history.actorUserId = actorUserId;
    history.actorName = actorName;
    await this.clientHealthHistoryRepository.save(history);

    // Tell the client's account manager, unless they made the change.
    const manager = client.accountManager;
    if (
      manager &&
      manager.userId !== actorUserId &&
      previousStatus !== dto.status
    ) {
      await this.notificationsService.create({
        recipientUserId: manager.userId,
        message: `${client.companyName}'s health changed from ${formatHealth(previousStatus)} to ${formatHealth(dto.status)}.`,
        linkTarget: NotificationLinkTarget.CLIENTS,
        linkEntityId: client.id,
      });
    }

    return toClientResponse(saved);
  }

  /** Daily heads-up for active monthly retainers about to renew: 30, 14 and 7
   * days out, to the project's owner and the client's account manager. Each
   * threshold is hit on exactly one day, so nobody is notified twice. */
  @Cron(CronExpression.EVERY_DAY_AT_8AM)
  async notifyUpcomingRenewals(): Promise<number> {
    const today = pakistanToday();
    const projects = await this.projectRepository.findAll();
    let sent = 0;
    for (const project of projects) {
      if (
        project.isArchived ||
        project.status !== ProjectStatus.ACTIVE ||
        project.type !== ProjectType.RETAINER ||
        !project.renewalDate
      ) {
        continue;
      }
      const days = daysBetween(today, project.renewalDate);
      if (!RENEWAL_REMINDER_DAYS.includes(days)) continue;

      const recipients = new Set<string>();
      if (project.accountManager) recipients.add(project.accountManager.userId);
      if (project.client.accountManager) {
        recipients.add(project.client.accountManager.userId);
      }
      for (const recipientUserId of recipients) {
        await this.notificationsService.create({
          recipientUserId,
          message: `${project.name} (${project.client.companyName}) renews in ${days} days, on ${project.renewalDate}.`,
          linkTarget: NotificationLinkTarget.CLIENTS_PROJECTS,
          linkEntityId: project.id,
        });
        sent += 1;
      }
    }
    return sent;
  }

  async getClientHealthHistory(
    id: string,
  ): Promise<ClientHealthHistoryResponseDto[]> {
    const history = await this.clientHealthHistoryRepository.findByClientId(id);
    return history.map(toClientHealthHistoryResponse);
  }

  async getClientHealthSummary(): Promise<ClientHealthSummaryDto> {
    const clients = await this.clientRepository.findAll(false);

    let healthyCount = 0;
    let attentionRequiredCount = 0;
    let atRiskCount = 0;

    for (const client of clients) {
      switch (client.healthStatus) {
        case ClientHealthStatus.HEALTHY:
          healthyCount += 1;
          break;
        case ClientHealthStatus.ATTENTION_REQUIRED:
          attentionRequiredCount += 1;
          break;
        case ClientHealthStatus.AT_RISK:
          atRiskCount += 1;
          break;
      }
    }

    return { healthyCount, attentionRequiredCount, atRiskCount };
  }

  // ---- Services ----

  async getServices(includeArchived: boolean): Promise<ServiceResponseDto[]> {
    const services = await this.serviceRepository.findAll(includeArchived);
    return services.map(toServiceResponse);
  }

  async createService(dto: CreateServiceDto): Promise<ServiceResponseDto> {
    const service = new Service();
    service.name = dto.name;
    service.description = dto.description;
    service.isArchived = false;

    const saved = await this.serviceRepository.save(service);
    return toServiceResponse(saved);
  }

  async updateService(
    id: string,
    dto: UpdateServiceDto,
  ): Promise<ServiceResponseDto> {
    const service = await this.serviceRepository.findById(id);
    if (!service) throw new NotFoundException('Service not found');
    Object.assign(service, definedFieldsOnly(dto));
    const saved = await this.serviceRepository.save(service);
    return toServiceResponse(saved);
  }

  // ---- Projects ----

  async getProjects(filters: {
    status?: ProjectStatus;
    clientId?: string;
    includeArchived?: boolean;
  }): Promise<ProjectResponseDto[]> {
    const projects = filters.clientId
      ? await this.projectRepository.findByClientId(filters.clientId)
      : await this.projectRepository.findAll();
    return projects
      .filter((project) => !filters.status || project.status === filters.status)
      .filter((project) => filters.includeArchived || !project.isArchived)
      .map(toProjectResponse);
  }

  async getProject(id: string): Promise<ProjectResponseDto> {
    return toProjectResponse(await this.getProjectOrThrow(id));
  }

  /** Sets the project's owner / account manager, who must be one of its
   * assigned employees. An empty/undefined id clears it. */
  private applyAccountManager(
    project: Project,
    accountManagerId: string | undefined,
  ): void {
    if (!accountManagerId) {
      project.accountManager = null;
      project.accountManagerId = null;
      return;
    }
    const manager = project.assignedEmployees.find(
      (employee) => employee.id === accountManagerId,
    );
    if (!manager) {
      throw new BadRequestException(
        'The account manager must be one of the assigned employees',
      );
    }
    project.accountManager = manager;
    project.accountManagerId = manager.id;
  }

  /** Every project needs a start date, plus the date that matches its type:
   * a one-time project needs a deadline, a monthly retainer a renewal date.
   * The deadline can't fall before the start. */
  private assertProjectDates(
    type: ProjectType,
    startDate: string | undefined,
    endDate: string | null | undefined,
    renewalDate: string | null | undefined,
  ): void {
    if (!startDate) {
      throw new BadRequestException('A project needs a start date');
    }
    if (type === ProjectType.RETAINER) {
      if (!renewalDate) {
        throw new BadRequestException('A monthly retainer needs a renewal date');
      }
      return;
    }
    if (!endDate) {
      throw new BadRequestException('A one-time project needs a deadline');
    }
    if (endDate < startDate) {
      throw new BadRequestException(
        'The deadline cannot be before the start date',
      );
    }
  }

  async createProject(dto: CreateProjectDto): Promise<ProjectResponseDto> {
    this.assertProjectDates(
      dto.type,
      dto.startDate,
      dto.endDate,
      dto.renewalDate,
    );
    const project = new Project();
    project.clientId = dto.clientId;
    project.name = dto.name;
    project.type = dto.type;
    project.status = dto.status ?? ProjectStatus.ACTIVE;
    project.startDate = dto.startDate;
    // Only the date that belongs to the project's type is kept.
    project.endDate =
      dto.type === ProjectType.ONE_TIME ? dto.endDate : null;
    project.renewalDate =
      dto.type === ProjectType.RETAINER ? dto.renewalDate : null;
    project.notes = dto.notes;
    project.backlinksTarget = dto.backlinksTarget;
    project.seoSheetName = dto.seoSheetName;
    project.projectFolderName = dto.projectFolderName;
    project.workingEmailAccount = dto.workingEmailAccount;
    project.ahrefsAccount = dto.ahrefsAccount;
    project.assignedEmployees = await this.resolveEmployees(
      dto.assignedEmployeeIds,
    );
    project.targetDepartments = await this.resolveDepartments(
      dto.targetDepartmentIds,
    );
    project.services = await this.resolveServices(dto.serviceIds);
    this.applyAccountManager(project, dto.accountManagerId);

    const saved = await this.projectRepository.save(project);
    return toProjectResponse(await this.getProjectOrThrow(saved.id));
  }

  async updateProject(
    id: string,
    dto: UpdateProjectDto,
  ): Promise<ProjectResponseDto> {
    const project = await this.getProjectOrThrow(id);
    const changes = definedFieldsOnly(dto);

    if (
      changes.isArchived !== undefined &&
      changes.isArchived !== project.isArchived
    ) {
      project.archivedAt = changes.isArchived ? new Date() : null;
    }
    if (changes.isArchived !== undefined) {
      project.isArchived = changes.isArchived;
    }

    if (changes.assignedEmployeeIds !== undefined) {
      project.assignedEmployees = await this.resolveEmployees(
        changes.assignedEmployeeIds,
      );
    }
    if (changes.targetDepartmentIds !== undefined) {
      project.targetDepartments = await this.resolveDepartments(
        changes.targetDepartmentIds,
      );
    }
    if (changes.serviceIds !== undefined) {
      project.services = await this.resolveServices(changes.serviceIds);
    }

    if (
      changes.accountManagerId !== undefined ||
      changes.assignedEmployeeIds !== undefined
    ) {
      this.applyAccountManager(
        project,
        changes.accountManagerId !== undefined
          ? changes.accountManagerId
          : (project.accountManagerId ?? ''),
      );
    }

    project.clientId = changes.clientId ?? project.clientId;
    project.name = changes.name ?? project.name;
    project.type = changes.type ?? project.type;
    project.status = changes.status ?? project.status;
    project.startDate = changes.startDate ?? project.startDate;
    if (changes.endDate !== undefined) project.endDate = changes.endDate;
    if (changes.renewalDate !== undefined) {
      project.renewalDate = changes.renewalDate;
    }
    if (changes.notes !== undefined) project.notes = changes.notes;
    // Re-check only when a date is being edited, so unrelated updates (e.g.
    // archiving an older project with no deadline) are never blocked.
    if (
      changes.type !== undefined ||
      changes.startDate !== undefined ||
      changes.endDate !== undefined ||
      changes.renewalDate !== undefined
    ) {
      this.assertProjectDates(
        project.type,
        project.startDate,
        project.endDate,
        project.renewalDate,
      );
      if (project.type === ProjectType.RETAINER) project.endDate = null;
      else project.renewalDate = null;
    }
    if (changes.backlinksTarget !== undefined) {
      project.backlinksTarget = changes.backlinksTarget;
    }
    if (changes.seoSheetName !== undefined) {
      project.seoSheetName = changes.seoSheetName;
    }
    if (changes.projectFolderName !== undefined) {
      project.projectFolderName = changes.projectFolderName;
    }
    if (changes.workingEmailAccount !== undefined) {
      project.workingEmailAccount = changes.workingEmailAccount;
    }
    if (changes.ahrefsAccount !== undefined) {
      project.ahrefsAccount = changes.ahrefsAccount;
    }

    const saved = await this.projectRepository.save(project);
    return toProjectResponse(await this.getProjectOrThrow(saved.id));
  }

  async getProjectsSummary(): Promise<ProjectsSummaryDto> {
    const projects = await this.projectRepository.findAll();

    let activeCount = 0;
    let onHoldCount = 0;
    let completedCount = 0;
    let cancelledCount = 0;

    for (const project of projects) {
      switch (project.status) {
        case ProjectStatus.ACTIVE:
          activeCount += 1;
          break;
        case ProjectStatus.ON_HOLD:
          onHoldCount += 1;
          break;
        case ProjectStatus.COMPLETED:
          completedCount += 1;
          break;
        case ProjectStatus.CANCELLED:
          cancelledCount += 1;
          break;
      }
    }

    return {
      activeCount,
      onHoldCount,
      completedCount,
      cancelledCount,
    };
  }

  private async getProjectOrThrow(id: string): Promise<Project> {
    const project = await this.projectRepository.findById(id);
    if (!project) throw new NotFoundException('Project not found');
    return project;
  }

  private async resolveEmployees(ids?: string[]): Promise<Employee[]> {
    if (!ids || ids.length === 0) return [];
    const all = await this.employeeRepository.findAll();
    return all.filter((employee) => ids.includes(employee.id));
  }

  private async resolveDepartments(ids?: string[]): Promise<Department[]> {
    if (!ids || ids.length === 0) return [];
    const all = await this.departmentRepository.findAll();
    return all.filter((department) => ids.includes(department.id));
  }

  private async resolveServices(ids?: string[]): Promise<Service[]> {
    if (!ids || ids.length === 0) return [];
    return this.serviceRepository.findByIds(ids);
  }
}
