import { NotFoundException } from '@nestjs/common';
import { Department } from '../../departments/domain/entities/department.entity';
import type { DepartmentRepository } from '../../departments/domain/repositories/department-repository.interface';
import { Employee } from '../../employee/domain/entities/employee.entity';
import type { EmployeeRepository } from '../../employee/domain/repositories/employee-repository.interface';
import { Client } from '../domain/entities/client.entity';
import { Project } from '../domain/entities/project.entity';
import { Service } from '../domain/entities/service.entity';
import { ProjectStatus } from '../domain/enums/project-status.enum';
import { ProjectType } from '../domain/enums/project-type.enum';
import type { ClientRepository } from '../domain/repositories/client-repository.interface';
import type { ProjectRepository } from '../domain/repositories/project-repository.interface';
import type { ServiceRepository } from '../domain/repositories/service-repository.interface';
import { ClientsService } from './clients.service';

function buildClient(overrides: Partial<Client> = {}): Client {
  return {
    id: 'client-1',
    companyName: 'Acme Inc',
    isArchived: false,
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
    originalClientPrice: '1000.00',
    deductionRate: '20.00',
    cost: '0.00',
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

    service = new ClientsService(
      clientRepository,
      serviceRepository,
      projectRepository,
      employeeRepository,
      departmentRepository,
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

    it('throws NotFoundException for a missing client', async () => {
      clientRepository.findById.mockResolvedValue(null);
      await expect(
        service.updateClient('missing', { companyName: 'X' }),
      ).rejects.toBeInstanceOf(NotFoundException);
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

  describe('projects — pricing', () => {
    it('defaults the deduction rate to 20% and computes netPrice/profit', async () => {
      projectRepository.findById.mockImplementation((id) =>
        Promise.resolve(buildProject({ id })),
      );

      const result = await service.createProject({
        clientId: 'client-1',
        name: 'Website Revamp',
        type: ProjectType.ONE_TIME,
        startDate: '2026-01-01',
        originalClientPrice: 1000,
      });

      expect(result.deductionRate).toBe(20);
      expect(result.netPrice).toBe(800);
      expect(result.profit).toBe(800);
    });

    it('honors a custom deduction rate and cost', async () => {
      projectRepository.findById.mockImplementation((id) =>
        Promise.resolve(
          buildProject({ id, deductionRate: '10.00', cost: '200.00' }),
        ),
      );

      const result = await service.createProject({
        clientId: 'client-1',
        name: 'Website Revamp',
        type: ProjectType.ONE_TIME,
        startDate: '2026-01-01',
        originalClientPrice: 1000,
        deductionRate: 10,
        cost: 200,
      });

      expect(result.netPrice).toBe(900);
      expect(result.profit).toBe(700);
    });

    it('recomputes netPrice/profit after an update', async () => {
      const project = buildProject();
      projectRepository.findById.mockResolvedValue(project);

      const result = await service.updateProject('project-1', {
        originalClientPrice: 2000,
        deductionRate: 25,
      });

      expect(result.netPrice).toBe(1500);
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
        originalClientPrice: 1000,
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
    it('counts by status and totals active retainer MRR and this-year one-time revenue', async () => {
      const thisYear = new Date().getFullYear();
      projectRepository.findAll.mockResolvedValue([
        buildProject({
          id: 'retainer-active',
          type: ProjectType.RETAINER,
          status: ProjectStatus.ACTIVE,
          originalClientPrice: '1000.00',
          deductionRate: '20.00',
        }),
        buildProject({
          id: 'retainer-completed',
          type: ProjectType.RETAINER,
          status: ProjectStatus.COMPLETED,
          originalClientPrice: '5000.00',
        }),
        buildProject({
          id: 'one-time-this-year',
          type: ProjectType.ONE_TIME,
          status: ProjectStatus.ACTIVE,
          startDate: `${thisYear}-03-01`,
          originalClientPrice: '500.00',
          deductionRate: '20.00',
        }),
        buildProject({
          id: 'one-time-last-year',
          type: ProjectType.ONE_TIME,
          status: ProjectStatus.COMPLETED,
          startDate: '2020-03-01',
          originalClientPrice: '999999.00',
        }),
      ]);

      const summary = await service.getProjectsSummary();

      expect(summary.activeCount).toBe(2);
      expect(summary.completedCount).toBe(2);
      expect(summary.activeMonthlyRecurringRevenue).toBe(800);
      expect(summary.oneTimeRevenueThisYear).toBe(400);
    });
  });
});
