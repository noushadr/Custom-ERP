import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import { CreateProjectDto } from '../application/dto/create-project.dto';
import { UpdateProjectDto } from '../application/dto/update-project.dto';
import { ClientsService } from '../application/clients.service';
import { ProjectStatus } from '../domain/enums/project-status.enum';

@Controller('projects')
@Permissions('clients.manage')
export class ProjectsController {
  constructor(private readonly clientsService: ClientsService) {}

  @Get()
  getProjects(
    @Query('status') status?: ProjectStatus,
    @Query('clientId') clientId?: string,
  ) {
    return this.clientsService.getProjects({ status, clientId });
  }

  @Post()
  createProject(@Body() dto: CreateProjectDto) {
    return this.clientsService.createProject(dto);
  }

  // Must come before @Get(':id') — otherwise "summary" would be captured as
  // the :id parameter instead of matching this route.
  @Get('summary')
  getProjectsSummary() {
    return this.clientsService.getProjectsSummary();
  }

  @Get(':id')
  getProject(@Param('id') id: string) {
    return this.clientsService.getProject(id);
  }

  @Patch(':id')
  updateProject(@Param('id') id: string, @Body() dto: UpdateProjectDto) {
    return this.clientsService.updateProject(id, dto);
  }
}
