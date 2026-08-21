import { Injectable } from '@nestjs/common';
import { ClientsService } from '../../clients/application/clients.service';
import { ProjectStatus } from '../../clients/domain/enums/project-status.enum';
import { ProjectType } from '../../clients/domain/enums/project-type.enum';
import { AgencyReportDto } from './agency-report.interface';

/** Formats a Date's own local Y/M/D as 'YYYY-MM-DD' — `.toISOString()` first
 * converts to UTC, which silently rolls a local-midnight date back a day for
 * any server running ahead of UTC (e.g. Asia/Karachi, UTC+5). */
function toIsoDate(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

@Injectable()
export class AgencyReportingService {
  constructor(private readonly clientsService: ClientsService) {}

  async getReport(from?: string, to?: string): Promise<AgencyReportDto> {
    const now = new Date();
    const resolvedFrom = from ?? toIsoDate(new Date(now.getFullYear(), now.getMonth(), 1));
    const resolvedTo = to ?? toIsoDate(now);

    const fromDate = new Date(resolvedFrom);
    const toDate = new Date(resolvedTo);
    toDate.setHours(23, 59, 59, 999);
    const inRange = (isoDate: string) => {
      const date = new Date(isoDate);
      return date >= fromDate && date <= toDate;
    };

    const [clients, projects] = await Promise.all([
      this.clientsService.getClients(true),
      this.clientsService.getProjects({}),
    ]);

    const projectsInRange = projects.filter((project) => inRange(project.startDate));

    let totalRevenue = 0;
    let totalCost = 0;
    let oneTimeRevenue = 0;
    const projectsByStatus = { active: 0, onHold: 0, completed: 0, cancelled: 0 };
    const profitByClient = new Map<string, { clientName: string; profit: number }>();

    for (const project of projectsInRange) {
      totalRevenue += project.netPrice;
      totalCost += project.cost;
      if (project.type === ProjectType.ONE_TIME) {
        oneTimeRevenue += project.netPrice;
      }
      switch (project.status) {
        case ProjectStatus.ACTIVE:
          projectsByStatus.active += 1;
          break;
        case ProjectStatus.ON_HOLD:
          projectsByStatus.onHold += 1;
          break;
        case ProjectStatus.COMPLETED:
          projectsByStatus.completed += 1;
          break;
        case ProjectStatus.CANCELLED:
          projectsByStatus.cancelled += 1;
          break;
      }

      const entry = profitByClient.get(project.clientId) ?? {
        clientName: project.clientName,
        profit: 0,
      };
      entry.profit += project.profit;
      profitByClient.set(project.clientId, entry);
    }

    // A live snapshot of current active retainers — not scoped to the
    // requested range, since "how much recurring revenue do we have right
    // now" doesn't make sense computed over a past window.
    let activeMonthlyRecurringRevenue = 0;
    for (const project of projects) {
      if (project.type === ProjectType.RETAINER && project.status === ProjectStatus.ACTIVE) {
        activeMonthlyRecurringRevenue += project.netPrice;
      }
    }

    const activeClientsCount = clients.filter((client) => !client.isArchived).length;
    const newClientsCount = clients.filter((client) => inRange(client.createdAt)).length;
    const lostClientsCount = clients.filter(
      (client) => client.archivedAt && inRange(client.archivedAt),
    ).length;

    const topClientsByProfit = [...profitByClient.entries()]
      .map(([clientId, value]) => ({
        clientId,
        clientName: value.clientName,
        profit: value.profit,
      }))
      .sort((a, b) => b.profit - a.profit)
      .slice(0, 5);

    return {
      from: resolvedFrom,
      to: resolvedTo,
      totalRevenue,
      totalCost,
      netProfit: totalRevenue - totalCost,
      activeMonthlyRecurringRevenue,
      oneTimeRevenue,
      activeClientsCount,
      newClientsCount,
      lostClientsCount,
      projectsByStatus,
      topClientsByProfit,
    };
  }
}
