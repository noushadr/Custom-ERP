import { ClientResponseDto, ProjectResponseDto } from '../../clients/application/client-response.interface';
import { ClientsService } from '../../clients/application/clients.service';
import { ClientHealthStatus } from '../../clients/domain/enums/client-health-status.enum';
import { ProjectPaymentStatus } from '../../clients/domain/enums/project-payment-status.enum';
import { ProjectStatus } from '../../clients/domain/enums/project-status.enum';
import { ProjectType } from '../../clients/domain/enums/project-type.enum';
import { AgencyReportingService } from './agency-reporting.service';

function buildClient(overrides: Partial<ClientResponseDto> = {}): ClientResponseDto {
  return {
    id: 'client-1',
    companyName: 'Acme Inc',
    industry: null,
    website: null,
    address: null,
    primaryContactName: null,
    primaryContactEmail: null,
    primaryContactPhone: null,
    notes: null,
    isArchived: false,
    archivedAt: null,
    healthStatus: ClientHealthStatus.HEALTHY,
    healthFactors: [],
    healthNotes: null,
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
    ...overrides,
  };
}

function buildProject(overrides: Partial<ProjectResponseDto> = {}): ProjectResponseDto {
  return {
    id: 'project-1',
    clientId: 'client-1',
    clientName: 'Acme Inc',
    name: 'Website Revamp',
    type: ProjectType.ONE_TIME,
    status: ProjectStatus.ACTIVE,
    startDate: '2026-03-01',
    endDate: null,
    renewalDate: null,
    originalClientPrice: 1000,
    deductionRate: 20,
    netPrice: 800,
    cost: 100,
    profit: 700,
    notes: null,
    paymentStatus: ProjectPaymentStatus.UNPAID,
    amountPaid: 0,
    assignedEmployees: [],
    targetDepartments: [],
    services: [],
    createdAt: '2026-03-01T00:00:00.000Z',
    updatedAt: '2026-03-01T00:00:00.000Z',
    ...overrides,
  };
}

describe('AgencyReportingService', () => {
  let service: AgencyReportingService;
  let clientsService: jest.Mocked<ClientsService>;

  beforeEach(() => {
    clientsService = {
      getClients: jest.fn().mockResolvedValue([]),
      getProjects: jest.fn().mockResolvedValue([]),
    } as unknown as jest.Mocked<ClientsService>;

    service = new AgencyReportingService(clientsService);
  });

  it('totals revenue, cost, and profit for projects starting within the range', async () => {
    clientsService.getProjects.mockResolvedValue([
      buildProject({ id: 'p1', startDate: '2026-03-10', netPrice: 800, cost: 100, profit: 700 }),
      buildProject({ id: 'p2', startDate: '2026-03-20', netPrice: 500, cost: 50, profit: 450 }),
      buildProject({ id: 'p3', startDate: '2026-04-01', netPrice: 9999, cost: 0, profit: 9999 }),
    ]);

    const report = await service.getReport('2026-03-01', '2026-03-31');

    expect(report.totalRevenue).toBe(1300);
    expect(report.totalCost).toBe(150);
    expect(report.netProfit).toBe(1150);
  });

  it('splits one-time revenue from retainer revenue', async () => {
    clientsService.getProjects.mockResolvedValue([
      buildProject({
        id: 'p1',
        type: ProjectType.ONE_TIME,
        startDate: '2026-03-10',
        netPrice: 800,
      }),
      buildProject({
        id: 'p2',
        type: ProjectType.RETAINER,
        status: ProjectStatus.ACTIVE,
        startDate: '2026-03-05',
        netPrice: 500,
      }),
    ]);

    const report = await service.getReport('2026-03-01', '2026-03-31');

    expect(report.oneTimeRevenue).toBe(800);
    // MRR is a live snapshot of active retainers, not scoped to the range.
    expect(report.activeMonthlyRecurringRevenue).toBe(500);
  });

  it('excludes cancelled/inactive retainers from active MRR', async () => {
    clientsService.getProjects.mockResolvedValue([
      buildProject({
        id: 'p1',
        type: ProjectType.RETAINER,
        status: ProjectStatus.CANCELLED,
        startDate: '2020-01-01',
        netPrice: 500,
      }),
    ]);

    const report = await service.getReport('2026-03-01', '2026-03-31');

    expect(report.activeMonthlyRecurringRevenue).toBe(0);
  });

  it('counts projects by status within the range', async () => {
    clientsService.getProjects.mockResolvedValue([
      buildProject({ id: 'p1', status: ProjectStatus.ACTIVE, startDate: '2026-03-01' }),
      buildProject({ id: 'p2', status: ProjectStatus.ON_HOLD, startDate: '2026-03-02' }),
      buildProject({ id: 'p3', status: ProjectStatus.COMPLETED, startDate: '2026-03-03' }),
      buildProject({ id: 'p4', status: ProjectStatus.CANCELLED, startDate: '2026-03-04' }),
    ]);

    const report = await service.getReport('2026-03-01', '2026-03-31');

    expect(report.projectsByStatus).toEqual({
      active: 1,
      onHold: 1,
      completed: 1,
      cancelled: 1,
    });
  });

  it('counts active, new, and lost clients', async () => {
    clientsService.getClients.mockResolvedValue([
      buildClient({ id: 'c1', isArchived: false, createdAt: '2026-03-05T00:00:00.000Z' }),
      buildClient({ id: 'c2', isArchived: false, createdAt: '2020-01-01T00:00:00.000Z' }),
      buildClient({
        id: 'c3',
        isArchived: true,
        createdAt: '2020-01-01T00:00:00.000Z',
        archivedAt: '2026-03-15T00:00:00.000Z',
      }),
    ]);

    const report = await service.getReport('2026-03-01', '2026-03-31');

    expect(report.activeClientsCount).toBe(2);
    expect(report.newClientsCount).toBe(1);
    expect(report.lostClientsCount).toBe(1);
  });

  it('ranks the top clients by profit within the range, most profitable first', async () => {
    clientsService.getProjects.mockResolvedValue([
      buildProject({
        id: 'p1',
        clientId: 'c1',
        clientName: 'Small Profit Co',
        startDate: '2026-03-01',
        profit: 100,
      }),
      buildProject({
        id: 'p2',
        clientId: 'c2',
        clientName: 'Big Profit Co',
        startDate: '2026-03-02',
        profit: 500,
      }),
      buildProject({
        id: 'p3',
        clientId: 'c2',
        clientName: 'Big Profit Co',
        startDate: '2026-03-03',
        profit: 200,
      }),
    ]);

    const report = await service.getReport('2026-03-01', '2026-03-31');

    expect(report.topClientsByProfit[0]).toEqual({
      clientId: 'c2',
      clientName: 'Big Profit Co',
      profit: 700,
    });
    expect(report.topClientsByProfit[1]).toEqual({
      clientId: 'c1',
      clientName: 'Small Profit Co',
      profit: 100,
    });
  });

  it('defaults to the current month when no range is given', async () => {
    const report = await service.getReport();

    // Built from local Y/M/D directly (not `.toISOString()`, which converts
    // to UTC first and would silently roll a local-midnight date back a day
    // on any machine running ahead of UTC — the exact bug this guards).
    const now = new Date();
    const pad = (n: number) => String(n).padStart(2, '0');
    const isoDate = (d: Date) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

    expect(report.from).toBe(isoDate(new Date(now.getFullYear(), now.getMonth(), 1)));
    expect(report.to).toBe(isoDate(now));
  });
});
