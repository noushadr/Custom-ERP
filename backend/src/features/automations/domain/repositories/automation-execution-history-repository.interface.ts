import { AutomationExecutionHistory } from '../entities/automation-execution-history.entity';
import { AutomationType } from '../enums/automation-type.enum';

export const AUTOMATION_EXECUTION_HISTORY_REPOSITORY = Symbol(
  'AUTOMATION_EXECUTION_HISTORY_REPOSITORY',
);

export interface AutomationExecutionHistoryRepository {
  findAll(type?: AutomationType): Promise<AutomationExecutionHistory[]>;
  save(
    entry: AutomationExecutionHistory,
  ): Promise<AutomationExecutionHistory>;
}
