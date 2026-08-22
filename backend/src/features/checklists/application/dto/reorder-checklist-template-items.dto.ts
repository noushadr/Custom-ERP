import { ArrayMinSize, IsArray, IsEnum, IsUUID } from 'class-validator';
import { ChecklistType } from '../../domain/enums/checklist-type.enum';

export class ReorderChecklistTemplateItemsDto {
  @IsEnum(ChecklistType)
  type: ChecklistType;

  /** Every template item id of this type, in the desired order. */
  @IsArray()
  @ArrayMinSize(1)
  @IsUUID('4', { each: true })
  orderedIds: string[];
}
