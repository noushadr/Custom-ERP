import { Injectable, Inject, NotFoundException } from '@nestjs/common';
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
    client.address = dto.address;
    client.primaryContactName = dto.primaryContactName;
    client.primaryContactEmail = dto.primaryContactEmail;
    client.primaryContactPhone = dto.primaryContactPhone;
    client.notes = dto.notes;
    client.isArchived = false;
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
    Object.assign(client, definedFieldsOnly(dto));
    const saved = await this.clientRepository.save(client);
    return toClientResponse(saved);
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

    return toClientResponse(saved);
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
  }): Promise<ProjectResponseDto[]> {
    const projects = filters.clientId
      ? await this.projectRepository.findByClientId(filters.clientId)
      : await this.projectRepository.findAll();
    return projects
      .filter((project) => !filters.status || project.status === filters.status)
      .map(toProjectResponse);
  }

  async getProject(id: string): Promise<ProjectResponseDto> {
    return toProjectResponse(await this.getProjectOrThrow(id));
  }

  async createProject(dto: CreateProjectDto): Promise<ProjectResponseDto> {
    const project = new Project();
    project.clientId = dto.clientId;
    project.name = dto.name;
    project.type = dto.type;
    project.status = dto.status ?? ProjectStatus.ACTIVE;
    project.startDate = dto.startDate;
    project.endDate = dto.endDate;
    project.renewalDate = dto.renewalDate;
    project.originalClientPrice = dto.originalClientPrice.toFixed(2);
    project.deductionRate = (dto.deductionRate ?? 20).toFixed(2);
    project.cost = (dto.cost ?? 0).toFixed(2);
    project.notes = dto.notes;
    project.assignedEmployees = await this.resolveEmployees(
      dto.assignedEmployeeIds,
    );
    project.targetDepartments = await this.resolveDepartments(
      dto.targetDepartmentIds,
    );
    project.services = await this.resolveServices(dto.serviceIds);

    const saved = await this.projectRepository.save(project);
    return toProjectResponse(await this.getProjectOrThrow(saved.id));
  }

  async updateProject(
    id: string,
    dto: UpdateProjectDto,
  ): Promise<ProjectResponseDto> {
    const project = await this.getProjectOrThrow(id);
    const changes = definedFieldsOnly(dto);

    if (changes.originalClientPrice !== undefined) {
      project.originalClientPrice = changes.originalClientPrice.toFixed(2);
    }
    if (changes.deductionRate !== undefined) {
      project.deductionRate = changes.deductionRate.toFixed(2);
    }
    if (changes.cost !== undefined) {
      project.cost = changes.cost.toFixed(2);
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

    const saved = await this.projectRepository.save(project);
    return toProjectResponse(await this.getProjectOrThrow(saved.id));
  }

  async getProjectsSummary(): Promise<ProjectsSummaryDto> {
    const projects = await this.projectRepository.findAll();
    const currentYear = new Date().getFullYear();

    let activeMonthlyRecurringRevenue = 0;
    let oneTimeRevenueThisYear = 0;
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

      const netPrice =
        Number(project.originalClientPrice) *
        (1 - Number(project.deductionRate) / 100);

      if (
        project.type === ProjectType.RETAINER &&
        project.status === ProjectStatus.ACTIVE
      ) {
        activeMonthlyRecurringRevenue += netPrice;
      }
      if (
        project.type === ProjectType.ONE_TIME &&
        new Date(project.startDate).getFullYear() === currentYear
      ) {
        oneTimeRevenueThisYear += netPrice;
      }
    }

    return {
      activeCount,
      onHoldCount,
      completedCount,
      cancelledCount,
      activeMonthlyRecurringRevenue,
      oneTimeRevenueThisYear,
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
