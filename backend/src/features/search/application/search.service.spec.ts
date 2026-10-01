import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import type { ClientsService } from '../../clients/application/clients.service';
import type { EmployeesService } from '../../employee/application/employees.service';
import type { KnowledgeBaseService } from '../../knowledge-base/application/knowledge-base.service';
import type { LeadsService } from '../../leads/application/leads.service';
import type { TasksService } from '../../tasks/application/tasks.service';
import { SearchService } from './search.service';

function buildViewer(overrides: Partial<JwtPayload> = {}): JwtPayload {
  return {
    sub: 'user-1',
    email: 'viewer@zeracreative.com',
    role: 'Employee',
    permissions: [],
    ...overrides,
  };
}

describe('SearchService', () => {
  let service: SearchService;
  let employeesService: jest.Mocked<EmployeesService>;
  let tasksService: jest.Mocked<TasksService>;
  let clientsService: jest.Mocked<ClientsService>;
  let knowledgeBaseService: jest.Mocked<KnowledgeBaseService>;
  let leadsService: jest.Mocked<LeadsService>;

  beforeEach(() => {
    employeesService = {
      findAll: jest.fn().mockResolvedValue([]),
    } as unknown as jest.Mocked<EmployeesService>;
    tasksService = {
      getMyTasks: jest.fn().mockResolvedValue([]),
      getTasksAssignedByMe: jest.fn().mockResolvedValue([]),
      getTeamTasks: jest.fn().mockResolvedValue([]),
    } as unknown as jest.Mocked<TasksService>;
    clientsService = {
      getClients: jest.fn().mockResolvedValue([]),
      getProjects: jest.fn().mockResolvedValue([]),
    } as unknown as jest.Mocked<ClientsService>;
    knowledgeBaseService = {
      getVisibleArticles: jest.fn().mockResolvedValue([]),
    } as unknown as jest.Mocked<KnowledgeBaseService>;
    leadsService = {
      getLeads: jest.fn().mockResolvedValue([]),
    } as unknown as jest.Mocked<LeadsService>;

    service = new SearchService(
      employeesService,
      tasksService,
      clientsService,
      knowledgeBaseService,
      leadsService,
    );
  });

  it('returns every category empty for a query under 2 characters', async () => {
    const result = await service.search(buildViewer(), 'a');

    expect(result).toEqual({
      employees: [],
      tasks: [],
      projects: [],
      clients: [],
      articles: [],
      leads: [],
    });
    expect(employeesService.findAll).not.toHaveBeenCalled();
  });

  it('matches employees by name, email, or employee code, case-insensitively', async () => {
    employeesService.findAll.mockResolvedValue([
      {
        id: 'e1',
        fullName: 'Jane Doe',
        email: 'jane.doe@zeracreative.com',
        employeeCode: 'ZC-00001',
        designation: 'Engineer',
        department: null,
      },
      {
        id: 'e2',
        fullName: 'John Smith',
        email: 'john.smith@zeracreative.com',
        employeeCode: 'ZC-00002',
        designation: null,
        department: { id: 'd1', name: 'Sales' },
      },
    ] as any);

    const result = await service.search(
      buildViewer({ permissions: ['employees.read'] }),
      'JANE',
    );

    expect(result.employees).toEqual([
      { id: 'e1', title: 'Jane Doe', subtitle: 'Engineer' },
    ]);
  });

  it('skips employees entirely without employees.read', async () => {
    employeesService.findAll.mockResolvedValue([
      { id: 'e1', fullName: 'Jane Doe', email: 'x@x.com', employeeCode: 'ZC' },
    ] as any);

    const result = await service.search(buildViewer(), 'jane');

    expect(result.employees).toEqual([]);
    expect(employeesService.findAll).not.toHaveBeenCalled();
  });

  it('searches every task a tasks.manage holder can see via getTeamTasks(true)', async () => {
    tasksService.getTeamTasks.mockResolvedValue([
      { id: 't1', title: 'Fix the login bug', assigneeName: 'Jane Doe' },
      { id: 't2', title: 'Unrelated task', assigneeName: null },
    ] as any);

    const result = await service.search(
      buildViewer({ permissions: ['tasks.manage'] }),
      'login',
    );

    expect(tasksService.getTeamTasks).toHaveBeenCalledWith('user-1', true);
    expect(tasksService.getMyTasks).not.toHaveBeenCalled();
    expect(result.tasks).toEqual([
      { id: 't1', title: 'Fix the login bug', subtitle: 'Jane Doe' },
    ]);
  });

  it('merges and de-duplicates my/assigned-by/team tasks for a non-manager', async () => {
    tasksService.getMyTasks.mockResolvedValue([
      { id: 't1', title: 'Shared task', assigneeName: 'Me' },
    ] as any);
    tasksService.getTasksAssignedByMe.mockResolvedValue([
      { id: 't1', title: 'Shared task', assigneeName: 'Me' },
    ] as any);
    tasksService.getTeamTasks.mockResolvedValue([
      { id: 't2', title: 'Team shared task', assigneeName: null },
    ] as any);

    const result = await service.search(buildViewer(), 'shared');

    expect(tasksService.getTeamTasks).toHaveBeenCalledWith('user-1', false);
    expect(result.tasks.map((t) => t.id).sort()).toEqual(['t1', 't2']);
  });

  it('searches clients and projects only with clients.manage', async () => {
    clientsService.getClients.mockResolvedValue([
      { id: 'c1', companyName: 'Acme Inc', primaryContactName: 'Jane' },
    ] as any);
    clientsService.getProjects.mockResolvedValue([
      { id: 'p1', name: 'Acme Retainer', clientName: 'Acme Inc' },
    ] as any);

    const withoutPermission = await service.search(buildViewer(), 'acme');
    expect(withoutPermission.clients).toEqual([]);
    expect(withoutPermission.projects).toEqual([]);
    expect(clientsService.getClients).not.toHaveBeenCalled();

    const result = await service.search(
      buildViewer({ permissions: ['clients.manage'] }),
      'acme',
    );
    expect(result.clients).toEqual([
      { id: 'c1', title: 'Acme Inc', subtitle: 'Jane' },
    ]);
    expect(result.projects).toEqual([
      { id: 'p1', title: 'Acme Retainer', subtitle: 'Acme Inc' },
    ]);
  });

  it('searches knowledge base articles for every viewer, reusing visibility filtering', async () => {
    knowledgeBaseService.getVisibleArticles.mockResolvedValue([
      { id: 'a1', title: 'Onboarding Guide', authorName: 'Jane Doe' },
    ] as any);

    const result = await service.search(buildViewer(), 'onboarding');

    expect(knowledgeBaseService.getVisibleArticles).toHaveBeenCalledWith(
      'user-1',
      false,
      false,
    );
    expect(result.articles).toEqual([
      { id: 'a1', title: 'Onboarding Guide', subtitle: 'By Jane Doe' },
    ]);
  });

  it('searches leads only with leads.manage', async () => {
    leadsService.getLeads.mockResolvedValue([
      { id: 'l1', fullName: 'Prospect One', companyName: 'Big Co' },
    ] as any);

    const withoutPermission = await service.search(buildViewer(), 'prospect');
    expect(withoutPermission.leads).toEqual([]);
    expect(leadsService.getLeads).not.toHaveBeenCalled();

    const result = await service.search(
      buildViewer({ permissions: ['leads.manage'] }),
      'prospect',
    );
    expect(result.leads).toEqual([
      { id: 'l1', title: 'Prospect One', subtitle: 'Big Co' },
    ]);
  });

  it('caps each category at 8 results', async () => {
    employeesService.findAll.mockResolvedValue(
      Array.from({ length: 12 }, (_, i) => ({
        id: `e${i}`,
        fullName: `Match ${i}`,
        email: 'x@x.com',
        employeeCode: 'ZC',
        designation: null,
        department: null,
      })) as any,
    );

    const result = await service.search(
      buildViewer({ permissions: ['employees.read'] }),
      'match',
    );

    expect(result.employees).toHaveLength(8);
  });
});
