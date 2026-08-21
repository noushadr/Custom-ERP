export interface AgencyReportProjectsByStatus {
  active: number;
  onHold: number;
  completed: number;
  cancelled: number;
}

export interface AgencyReportClientProfit {
  clientId: string;
  clientName: string;
  profit: number;
}

/** A company-wide reporting snapshot over [from, to] — every figure below
 * (except `activeMonthlyRecurringRevenue`, a live snapshot) is scoped to
 * projects whose `startDate` falls in that range. "Outstanding payments" and
 * per-employee costs are deliberately not included: this app has no
 * invoice/payment ledger or time-allocation data yet — see CLAUDE.md's
 * Finances module (not started) and Project's manual `cost` field. */
export interface AgencyReportDto {
  from: string;
  to: string;
  totalRevenue: number;
  totalCost: number;
  netProfit: number;
  activeMonthlyRecurringRevenue: number;
  oneTimeRevenue: number;
  activeClientsCount: number;
  newClientsCount: number;
  lostClientsCount: number;
  projectsByStatus: AgencyReportProjectsByStatus;
  topClientsByProfit: AgencyReportClientProfit[];
}
