import { Injectable } from '@nestjs/common';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { EmployeesService } from '../../employee/application/employees.service';
import { EmployeeResponse } from '../../employee/application/employee-response.interface';
import { TasksService } from '../../tasks/application/tasks.service';
import { TaskResponseDto } from '../../tasks/application/task-response.interface';
import { ClientsService } from '../../clients/application/clients.service';
import {
  ClientResponseDto,
  ProjectResponseDto,
} from '../../clients/application/client-response.interface';
import { KnowledgeBaseService } from '../../knowledge-base/application/knowledge-base.service';
import { KnowledgeBaseArticleSummaryDto } from '../../knowledge-base/application/knowledge-base-article-response.interface';
import { LeadsService } from '../../leads/application/leads.service';
import { LeadResponseDto } from '../../leads/application/lead-response.interface';
import {
  SearchResponseDto,
  SearchResultItem,
} from './search-response.interface';

const RESULTS_PER_CATEGORY = 8;
const KNOWLEDGE_BASE_PERMISSION = 'knowledge_base.manage';
const TASKS_PERMISSION = 'tasks.manage';

@Injectable()
export class SearchService {
  constructor(
    private readonly employeesService: EmployeesService,
    private readonly tasksService: TasksService,
    private readonly clientsService: ClientsService,
    private readonly knowledgeBaseService: KnowledgeBaseService,
    private readonly leadsService: LeadsService,
  ) {}

  /** Every category a viewer's own permissions already unlock elsewhere in
   * the app — never a wider search than what they could already reach by
   * browsing to that module's own page. A category requiring a permission
   * the viewer lacks is skipped entirely (its array stays empty) rather than
   * queried and then filtered, so there's no risk of a stray unguarded
   * query against a module the viewer can't otherwise see. */
  async search(
    viewer: JwtPayload,
    rawQuery: string,
  ): Promise<SearchResponseDto> {
    const query = rawQuery.trim().toLowerCase();
    const empty: SearchResponseDto = {
      employees: [],
      tasks: [],
      projects: [],
      clients: [],
      articles: [],
      leads: [],
    };
    if (query.length < 2) return empty;

    const [employees, tasks, projectsAndClients, articles, leads] =
      await Promise.all([
        this.searchEmployees(viewer, query),
        this.searchTasks(viewer, query),
        this.searchProjectsAndClients(viewer, query),
        this.searchArticles(viewer, query),
        this.searchLeads(viewer, query),
      ]);

    return {
      employees,
      tasks,
      projects: projectsAndClients.projects,
      clients: projectsAndClients.clients,
      articles,
      leads,
    };
  }

  private async searchEmployees(
    viewer: JwtPayload,
    query: string,
  ): Promise<SearchResultItem[]> {
    if (!viewer.permissions.includes('employees.read')) return [];
    const employees = await this.employeesService.findAll(viewer);
    return employees
      .filter((employee) => this.employeeMatches(employee, query))
      .slice(0, RESULTS_PER_CATEGORY)
      .map((employee) => ({
        id: employee.id,
        title: employee.fullName,
        subtitle: employee.designation ?? employee.department?.name ?? null,
      }));
  }

  private employeeMatches(employee: EmployeeResponse, query: string): boolean {
    return (
      employee.fullName.toLowerCase().includes(query) ||
      employee.email.toLowerCase().includes(query) ||
      employee.employeeCode.toLowerCase().includes(query)
    );
  }

  private async searchTasks(
    viewer: JwtPayload,
    query: string,
  ): Promise<SearchResultItem[]> {
    const actorHasOverride = viewer.permissions.includes(TASKS_PERMISSION);
    const lists = actorHasOverride
      ? [await this.tasksService.getTeamTasks(viewer.sub, true)]
      : await Promise.all([
          this.tasksService.getMyTasks(viewer.sub),
          this.tasksService.getTasksAssignedByMe(viewer.sub),
          this.tasksService.getTeamTasks(viewer.sub, false),
        ]);

    const byId = new Map<string, TaskResponseDto>();
    for (const list of lists) {
      for (const task of list) byId.set(task.id, task);
    }

    return Array.from(byId.values())
      .filter((task) => task.title.toLowerCase().includes(query))
      .slice(0, RESULTS_PER_CATEGORY)
      .map((task) => ({
        id: task.id,
        title: task.title,
        subtitle: task.assigneeName ?? 'Unclaimed',
      }));
  }

  private async searchProjectsAndClients(
    viewer: JwtPayload,
    query: string,
  ): Promise<{ projects: SearchResultItem[]; clients: SearchResultItem[] }> {
    if (!viewer.permissions.includes('clients.manage')) {
      return { projects: [], clients: [] };
    }

    const [clients, projects] = await Promise.all([
      this.clientsService.getClients(false),
      this.clientsService.getProjects({ includeArchived: false }),
    ]);

    const matchedClients = clients.filter((client) =>
      this.clientMatches(client, query),
    );
    const matchedProjects = projects.filter((project) =>
      this.projectMatches(project, query),
    );

    return {
      clients: matchedClients.slice(0, RESULTS_PER_CATEGORY).map((client) => ({
        id: client.id,
        title: client.companyName,
        subtitle: client.primaryContactName,
      })),
      projects: matchedProjects
        .slice(0, RESULTS_PER_CATEGORY)
        .map((project) => ({
          id: project.id,
          title: project.name,
          subtitle: project.clientName,
        })),
    };
  }

  private clientMatches(client: ClientResponseDto, query: string): boolean {
    return client.companyName.toLowerCase().includes(query);
  }

  private projectMatches(project: ProjectResponseDto, query: string): boolean {
    return (
      project.name.toLowerCase().includes(query) ||
      project.clientName.toLowerCase().includes(query)
    );
  }

  private async searchArticles(
    viewer: JwtPayload,
    query: string,
  ): Promise<SearchResultItem[]> {
    const actorHasOverride = viewer.permissions.includes(
      KNOWLEDGE_BASE_PERMISSION,
    );
    const articles = await this.knowledgeBaseService.getVisibleArticles(
      viewer.sub,
      actorHasOverride,
      false,
    );
    return articles
      .filter((article) => this.articleMatches(article, query))
      .slice(0, RESULTS_PER_CATEGORY)
      .map((article) => ({
        id: article.id,
        title: article.title,
        subtitle: `By ${article.authorName}`,
      }));
  }

  private articleMatches(
    article: KnowledgeBaseArticleSummaryDto,
    query: string,
  ): boolean {
    return article.title.toLowerCase().includes(query);
  }

  private async searchLeads(
    viewer: JwtPayload,
    query: string,
  ): Promise<SearchResultItem[]> {
    if (!viewer.permissions.includes('leads.manage')) return [];
    const leads = await this.leadsService.getLeads();
    return leads
      .filter((lead) => this.leadMatches(lead, query))
      .slice(0, RESULTS_PER_CATEGORY)
      .map((lead) => ({
        id: lead.id,
        title: lead.fullName,
        subtitle: lead.companyName,
      }));
  }

  private leadMatches(lead: LeadResponseDto, query: string): boolean {
    return (
      lead.fullName.toLowerCase().includes(query) ||
      (lead.companyName?.toLowerCase().includes(query) ?? false)
    );
  }
}
