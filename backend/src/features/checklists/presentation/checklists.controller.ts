import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import { ChecklistsService } from '../application/checklists.service';
import { CreateChecklistTemplateItemDto } from '../application/dto/create-checklist-template-item.dto';
import { ReorderChecklistTemplateItemsDto } from '../application/dto/reorder-checklist-template-items.dto';
import { UpdateChecklistTemplateItemDto } from '../application/dto/update-checklist-template-item.dto';
import { ChecklistType } from '../domain/enums/checklist-type.enum';

@Controller('checklists')
export class ChecklistsController {
  constructor(private readonly checklistsService: ChecklistsService) {}

  @Get('templates')
  getTemplateItems(
    @Query('type') type: ChecklistType,
    @Query('includeArchived') includeArchived?: string,
  ) {
    return this.checklistsService.getTemplateItems(
      type,
      includeArchived === 'true',
    );
  }

  // Must come before @Patch('templates/:id') — otherwise "reorder" would be
  // captured as the :id parameter instead of matching this route.
  @Patch('templates/reorder')
  @Permissions('employees.manage')
  reorderTemplateItems(@Body() dto: ReorderChecklistTemplateItemsDto) {
    return this.checklistsService.reorderTemplateItems(dto);
  }

  @Post('templates')
  @Permissions('employees.manage')
  createTemplateItem(@Body() dto: CreateChecklistTemplateItemDto) {
    return this.checklistsService.createTemplateItem(dto);
  }

  @Patch('templates/:id')
  @Permissions('employees.manage')
  updateTemplateItem(
    @Param('id') id: string,
    @Body() dto: UpdateChecklistTemplateItemDto,
  ) {
    return this.checklistsService.updateTemplateItem(id, dto);
  }

  @Delete('templates/:id')
  @Permissions('employees.manage')
  @HttpCode(204)
  deleteTemplateItem(@Param('id') id: string) {
    return this.checklistsService.deleteTemplateItem(id);
  }
}
