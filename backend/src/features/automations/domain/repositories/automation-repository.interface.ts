import { Automation } from '../entities/automation.entity';
import { AutomationType } from '../enums/automation-type.enum';

export const AUTOMATION_REPOSITORY = Symbol('AUTOMATION_REPOSITORY');

export interface AutomationRepository {
  findAll(): Promise<Automation[]>;
  findByType(type: AutomationType): Promise<Automation | null>;
  save(automation: Automation): Promise<Automation>;
}
