export interface AutomationResponseDto {
  type: string;
  isActive: boolean;
  daysBefore: number | null;
  updatedByName: string | null;
  updatedAt: string;
}

export interface AutomationExecutionHistoryResponseDto {
  id: string;
  type: string;
  triggeredBy: string;
  status: string;
  itemsProcessed: number;
  notificationsCreated: number;
  errorMessage: string | null;
  runAt: string;
}
