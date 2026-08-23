import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import { CreateLeadDto } from '../application/dto/create-lead.dto';
import { UpdateLeadDto } from '../application/dto/update-lead.dto';
import { LeadsService } from '../application/leads.service';

@Controller('leads')
@Permissions('leads.manage')
export class LeadsController {
  constructor(private readonly leadsService: LeadsService) {}

  @Get()
  getLeads(@Query('includeArchived') includeArchived?: string) {
    return this.leadsService.getLeads(includeArchived === 'true');
  }

  @Post()
  createLead(@Body() dto: CreateLeadDto) {
    return this.leadsService.createLead(dto);
  }

  @Patch(':id')
  updateLead(@Param('id') id: string, @Body() dto: UpdateLeadDto) {
    return this.leadsService.updateLead(id, dto);
  }
}
