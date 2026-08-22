import { Automation } from '../domain/entities/automation.entity';
import { AutomationExecutionHistory } from '../domain/entities/automation-execution-history.entity';
import {
  AutomationExecutionHistoryResponseDto,
  AutomationResponseDto,
} from './automations-response.interface';

export function toAutomationResponse(
  automation: Automation,
): AutomationResponseDto {
  return {
    type: automation.type,
    isActive: automation.isActive,
    daysBefore: automation.daysBefore,
    updatedByName: automation.updatedByName ?? null,
    updatedAt: automation.updatedAt.toISOString(),
  };
}

export function toAutomationExecutionHistoryResponse(
  entry: AutomationExecutionHistory,
): AutomationExecutionHistoryResponseDto {
  return {
    id: entry.id,
    type: entry.type,
    triggeredBy: entry.triggeredBy,
    status: entry.status,
    itemsProcessed: entry.itemsProcessed,
    notificationsCreated: entry.notificationsCreated,
    errorMessage: entry.errorMessage,
    runAt: entry.createdAt.toISOString(),
  };
}
