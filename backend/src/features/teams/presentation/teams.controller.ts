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
import { CreateTeamDto } from '../application/dto/create-team.dto';
import { UpdateTeamDto } from '../application/dto/update-team.dto';
import { TeamsService } from '../application/teams.service';

@Controller('teams')
export class TeamsController {
  constructor(private readonly teamsService: TeamsService) {}

  @Get()
  findAll(
    @Query('departmentId') departmentId?: string,
    @Query('includeArchived') includeArchived?: string,
  ) {
    return this.teamsService.findAll(departmentId, includeArchived === 'true');
  }

  @Post()
  @Permissions('teams.manage')
  create(@Body() dto: CreateTeamDto) {
    return this.teamsService.create(dto);
  }

  @Patch(':id')
  @Permissions('teams.manage')
  update(@Param('id') id: string, @Body() dto: UpdateTeamDto) {
    return this.teamsService.update(id, dto);
  }

  @Delete(':id')
  @Permissions('teams.manage')
  @HttpCode(204)
  remove(@Param('id') id: string) {
    return this.teamsService.remove(id);
  }
}
