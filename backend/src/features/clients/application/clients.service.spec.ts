import { NotFoundException } from '@nestjs/common';
import type { UserRepository } from '../../authentication/domain/repositories/user-repository.interface';
import { Department } from '../../departments/domain/entities/department.entity';
import type { DepartmentRepository } from '../../departments/domain/repositories/department-repository.interface';
import { Employee } from '../../employee/domain/entities/employee.entity';
import type { EmployeeRepository } from '../../employee/domain/repositories/employee-repository.interface';
import { Client } from '../domain/entities/client.entity';
import { ClientHealthHistory } from '../domain/entities/client-health-history.entity';
import { Project } from '../domain/entities/project.entity';
import { Service } from '../domain/entities/service.entity';
import { ClientHealthFactor } from '../domain/enums/client-health-factor.enum';
import { ClientHealthStatus } from '../domain/enums/client-health-status.enum';
import { ProjectStatus } from '../domain/enums/project-status.enum';
import { ProjectType } from '../domain/enums/project-type.enum';
import type { ClientHealthHistoryRepository } from '../domain/repositories/client-health-history-repository.interface';
import type { ClientRepository } from '../domain/repositories/client-repository.interface';
import type { ProjectRepository } from '../domain/repositories/project-repository.interface';
import type { ServiceRepository } from '../domain/repositories/service-repository.interface';
import { ClientsService } from './clients.service';

function buildClient(overrides: Partial<Client> = {}): Client {
  return {
    id: 'client-1',
    companyName: 'Acme Inc',
    isArchived: false,
    healthStatus: ClientHealthStatus.HEALTHY,
    healthFactors: [],
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    updatedAt: new Date('2026-01-01T00:00:00.000Z'),
    ...overrides,
  } as Client;
}

function buildService(overrides: Partial<Service> = {}): Service {
  return {
    id: 'service-1',
    name: 'SEO',
    isArchived: false,
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    updatedAt: new Date('2026-01-01T00:00:00.000Z'),
    ...overrides,
  } as Service;
}

function buildEmployee(overrides: Partial<Employee> = {}): Employee {
  return {
    id: 'employee-1',
    firstName: 'Jane',
    lastName: 'Doe',
    profilePhotoUrl: undefined,
    ...overrides,
  } as Employee;
}

function buildDepartment(overrides: Partial<Department> = {}): Department {
  return { id: 'dept-1', name: 'Engineering', ...overrides } as Department;
}

function buildProject(overrides: Partial<Project> = {}): Project {
  return {
    id: 'project-1',
    clientId: 'client-1',
    client: buildClient(),
    name: 'Website Revamp',
    type: ProjectType.ONE_TIME,
    status: ProjectStatus.ACTIVE,
    startDate: '2026-01-01',
    assignedEmployees: [],
    targetDepartments: [],
    services: [],
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    updatedAt: new Date('2026-01-01T00:00:00.000Z'),
    ...overrides,
  } as Project;
}

describe('ClientsService', () => {
  let service: ClientsService;
  let clientRepository: jest.Mocked<ClientRepository>;
  let serviceRepository: jest.Mocked<ServiceRepository>;
  let projectRepository: jest.Mocked<ProjectRepository>;
  let employeeRepository: jest.Mocked<EmployeeRepository>;
  let departmentRepository: jest.Mocked<DepartmentRepository>;
  let clientHealthHistoryRepository: jest.Mocked<ClientHealthHistoryRepository>;
  let userRepository: jest.Mocked<UserRepository>;

  beforeEach(() => {
    const stampTimestamps = (item: {
      createdAt?: Date;
      updatedAt?: Date;
    }) => ({
      ...item,
      createdAt: item.createdAt ?? new Date('2026-01-01T00:00:00.000Z'),
      updatedAt: item.updatedAt ?? new Date('2026-01-01T00:00:00.000Z'),
    });

    clientRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      save: jest.fn((item) => Promise.resolve(stampTimestamps(item) as Client)),
    };
    serviceRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      findByIds: jest.fn().mockResolvedValue([]),
      save: jest.fn((item) =>
        Promise.resolve(stampTimestamps(item) as Service),
      ),
    };
    projectRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findByClientId: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      save: jest.fn((item) => Promise.resolve(item)),
    };
    employeeRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      findByUserId: jest.fn(),
      findByReportingManagerId: jest.fn(),
      count: jest.fn(),
      save: jest.fn(),
    };
    departmentRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      save: jest.fn(),
      remove: jest.fn(),
    };
    clientHealthHistoryRepository = {
      findByClientId: jest.fn().mockResolvedValue([]),
      save: jest.fn((item) =>
        Promise.resolve(stampTimestamps(item) as ClientHealthHistory),
      ),
    };
    userRepository = {
      findByEmail: jest.fn(),
      findById: jest.fn().mockResolvedValue(null),
      findAll: jest.fn(),
      save: jest.fn(),
    };

    service = new ClientsService(
      clientRepository,
      serviceRepository,
      projectRepository,
      employeeRepository,
      departmentRepository,
      clientHealthHistoryRepository,
      userRepository,
    );
  });

  describe('clients', () => {
    it('lists only non-archived clients by default', async () => {
      await service.getClients(false);
      expect(clientRepository.findAll).toHaveBeenCalledWith(false);
    });

    it('creates a client', async () => {
      const result = await service.createClient({ companyName: 'Acme Inc' });
      expect(result.companyName).toBe('Acme Inc');
      expect(result.isArchived).toBe(false);
    });

    it('updates a client, including archiving it', async () => {
      clientRepository.findById.mockResolvedValue(buildClient());

      const result = await service.updateClient('client-1', {
        isArchived: true,
      });

      expect(result.isArchived).toBe(true);
    });

    it('stamps archivedAt when a client is archived, and clears it on reactivation', async () => {
      const client = buildClient();
      clientRepository.findById.mockResolvedValue(client);

      const archived = await service.updateClient('client-1', {
        isArchived: true,
      });
      expect(archived.archivedAt).not.toBeNull();

      clientRepository.findById.mockResolvedValue(client);
      const reactivated = await service.updateClient('client-1', {
        isArchived: false,
      });
      expect(reactivated.archivedAt).toBeNull();
    });

    it('leaves archivedAt untouched when isArchived is unchanged', async () => {
      clientRepository.findById.mockResolvedValue(buildClient());

      const result = await service.updateClient('client-1', {
        companyName: 'Acme Renamed',
      });

      expect(result.archivedAt).toBeNull();
    });

    it('throws NotFoundException for a missing client', async () => {
      clientRepository.findById.mockResolvedValue(null);
      await expect(
        service.updateClient('missing', { companyName: 'X' }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('client health', () => {
    it('defaults a new client to Healthy with no factors or notes', async () => {
      const result = await service.createClient({ companyName: 'Acme Inc' });
      expect(result.healthStatus).toBe(ClientHealthStatus.HEALTHY);
      expect(result.healthFactors).toEqual([]);
      expect(result.healthNotes).toBeNull();
    });

    it('updates the client row and writes a history row on a health update', async () => {
      clientRepository.findById.mockResolvedValue(
        buildClient({ healthStatus: ClientHealthStatus.HEALTHY }),
      );
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ firstName: 'Jane', lastName: 'Admin' }),
      );

      const result = await service.updateClientHealth('client-1', 'user-1', {
        status: ClientHealthStatus.AT_RISK,
        factors: [ClientHealthFactor.PAYMENT, ClientHealthFactor.DELAYS],
        notes: 'Invoice overdue 30 days',
      });

      expect(result.healthStatus).toBe(ClientHealthStatus.AT_RISK);
      expect(result.healthFactors).toEqual([
        ClientHealthFactor.PAYMENT,
        ClientHealthFactor.DELAYS,
      ]);
      expect(result.healthNotes).toBe('Invoice overdue 30 days');

      expect(clientHealthHistoryRepository.save).toHaveBeenCalledTimes(1);
      const savedHistory = clientHealthHistoryRepository.save.mock
        .calls[0][0];
      expect(savedHistory.previousStatus).toBe(ClientHealthStatus.HEALTHY);
      expect(savedHistory.newStatus).toBe(ClientHealthStatus.AT_RISK);
      expect(savedHistory.factors).toEqual([
        ClientHealthFactor.PAYMENT,
        ClientHealthFactor.DELAYS,
      ]);
      expect(savedHistory.actorUserId).toBe('user-1');
      expect(savedHistory.actorName).toBe('Jane Admin');
    });

    it('defaults factors to an empty array and notes to null when omitted', async () => {
      clientRepository.findById.mockResolvedValue(buildClient());

      await service.updateClientHealth('client-1', 'user-1', {
        status: ClientHealthStatus.ATTENTION_REQUIRED,
      });

      const savedHistory = clientHealthHistoryRepository.save.mock
        .calls[0][0];
      expect(savedHistory.factors).toEqual([]);
      expect(savedHistory.notes).toBeNull();
    });

    it('falls back to a name derived from the email when there is no employee profile', async () => {
      clientRepository.findById.mockResolvedValue(buildClient());
      userRepository.findById.mockResolvedValue({
        email: 'noushad.ranani@zeracreative.com',
      } as any);

      await service.updateClientHealth('client-1', 'admin-user', {
        status: ClientHealthStatus.AT_RISK,
      });

      const savedHistory = clientHealthHistoryRepository.save.mock
        .calls[0][0];
      expect(savedHistory.actorName).toBe('Noushad Ranani');
    });

    it('returns health history newest-first', async () => {
      clientHealthHistoryRepository.findByClientId.mockResolvedValue([
        {
          id: 'h2',
          clientId: 'client-1',
          previousStatus: ClientHealthStatus.ATTENTION_REQUIRED,
          newStatus: ClientHealthStatus.AT_RISK,
          factors: [],
          notes: null,
          actorUserId: 'user-1',
          actorName: 'Jane Admin',
          createdAt: new Date('2026-02-01T00:00:00.000Z'),
          updatedAt: new Date('2026-02-01T00:00:00.000Z'),
        } as unknown as ClientHealthHistory,
      ]);

      const history = await service.getClientHealthHistory('client-1');

      expect(clientHealthHistoryRepository.findByClientId).toHaveBeenCalledWith(
        'client-1',
      );
      expect(history).toHaveLength(1);
      expect(history[0].newStatus).toBe(ClientHealthStatus.AT_RISK);
    });

    it('summarizes health counts across non-archived clients', async () => {
      clientRepository.findAll.mockResolvedValue([
        buildClient({ id: 'c1', healthStatus: ClientHealthStatus.HEALTHY }),
        buildClient({ id: 'c2', healthStatus: ClientHealthStatus.HEALTHY }),
        buildClient({
          id: 'c3',
          healthStatus: ClientHealthStatus.ATTENTION_REQUIRED,
        }),
        buildClient({ id: 'c4', healthStatus: ClientHealthStatus.AT_RISK }),
      ]);

      const summary = await service.getClientHealthSummary();

      expect(clientRepository.findAll).toHaveBeenCalledWith(false);
      expect(summary).toEqual({
        healthyCount: 2,
        attentionRequiredCount: 1,
        atRiskCount: 1,
      });
    });
  });

  describe('services', () => {
    it('creates a service', async () => {
      const result = await service.createService({ name: 'SEO' });
      expect(result.name).toBe('SEO');
    });

    it('archives a service', async () => {
      serviceRepository.findById.mockResolvedValue(buildService());
      const result = await service.updateService('service-1', {
        isArchived: true,
      });
      expect(result.isArchived).toBe(true);
    });
  });

  describe('projects — assignment resolution', () => {
    it('resolves assigned employees, departments, and services by id', async () => {
      employeeRepository.findAll.mockResolvedValue([
        buildEmployee({ id: 'employee-1' }),
        buildEmployee({ id: 'employee-2' }),
      ]);
      departmentRepository.findAll.mockResolvedValue([
        buildDepartment({ id: 'dept-1' }),
      ]);
      serviceRepository.findByIds.mockResolvedValue([
        buildService({ id: 'service-1' }),
      ]);
      projectRepository.findById.mockImplementation((id) =>
        Promise.resolve(
          buildProject({
            id,
            assignedEmployees: [buildEmployee({ id: 'employee-1' })],
            targetDepartments: [buildDepartment({ id: 'dept-1' })],
            services: [buildService({ id: 'service-1' })],
          }),
        ),
      );

      const result = await service.createProject({
        clientId: 'client-1',
        name: 'Website Revamp',
        type: ProjectType.ONE_TIME,
        startDate: '2026-01-01',
        assignedEmployeeIds: ['employee-1'],
        targetDepartmentIds: ['dept-1'],
        serviceIds: ['service-1'],
      });

      expect(result.assignedEmployees).toHaveLength(1);
      expect(result.assignedEmployees[0].id).toBe('employee-1');
      expect(result.targetDepartments[0].id).toBe('dept-1');
      expect(result.services[0].id).toBe('service-1');
    });
  });

  describe('projects — listing and filters', () => {
    it('filters by status', async () => {
      projectRepository.findAll.mockResolvedValue([
        buildProject({ id: 'p1', status: ProjectStatus.ACTIVE }),
        buildProject({ id: 'p2', status: ProjectStatus.COMPLETED }),
      ]);

      const result = await service.getProjects({
        status: ProjectStatus.ACTIVE,
      });

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('p1');
    });

    it('filters by client', async () => {
      projectRepository.findByClientId.mockResolvedValue([buildProject()]);

      await service.getProjects({ clientId: 'client-1' });

      expect(projectRepository.findByClientId).toHaveBeenCalledWith(
        'client-1',
      );
    });
  });

  describe('getProjectsSummary', () => {
    it('counts projects by status', async () => {
      projectRepository.findAll.mockResolvedValue([
        buildProject({ id: 'p1', status: ProjectStatus.ACTIVE }),
        buildProject({ id: 'p2', status: ProjectStatus.ACTIVE }),
        buildProject({ id: 'p3', status: ProjectStatus.ON_HOLD }),
        buildProject({ id: 'p4', status: ProjectStatus.COMPLETED }),
        buildProject({ id: 'p5', status: ProjectStatus.CANCELLED }),
      ]);

      const summary = await service.getProjectsSummary();

      expect(summary).toEqual({
        activeCount: 2,
        onHoldCount: 1,
        completedCount: 1,
        cancelledCount: 1,
      });
    });
  });
});
