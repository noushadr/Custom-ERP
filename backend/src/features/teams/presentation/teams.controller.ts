import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import { CreateTeamDto } from '../application/dto/create-team.dto';
import { TeamsService } from '../application/teams.service';

@Controller('teams')
export class TeamsController {
  constructor(private readonly teamsService: TeamsService) {}

  @Get()
  findAll(@Query('departmentId') departmentId?: string) {
    return this.teamsService.findAll(departmentId);
  }

  @Post()
  @Permissions('teams.manage')
  create(@Body() dto: CreateTeamDto) {
    return this.teamsService.create(dto);
  }
}
