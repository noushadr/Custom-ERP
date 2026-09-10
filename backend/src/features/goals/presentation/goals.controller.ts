import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { CurrentUser } from '../../authentication/presentation/decorators/current-user.decorator';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { BulkAssignGoalDto } from '../application/dto/bulk-assign-goal.dto';
import { CreateGoalDto } from '../application/dto/create-goal.dto';
import { UpdateGoalDto } from '../application/dto/update-goal.dto';
import { GoalsService } from '../application/goals.service';

@Controller('goals')
export class GoalsController {
  constructor(private readonly goalsService: GoalsService) {}

  @Get()
  @Permissions('goals.manage')
  findAll() {
    return this.goalsService.findAll();
  }

  @Get('me')
  findMine(@CurrentUser() user: JwtPayload) {
    return this.goalsService.findMine(user.sub);
  }

  @Get('team')
  findForMyTeam(@CurrentUser() user: JwtPayload) {
    return this.goalsService.findForMyTeam(user.sub);
  }

  @Post()
  @Permissions('goals.manage')
  create(@Body() dto: CreateGoalDto, @CurrentUser() user: JwtPayload) {
    return this.goalsService.createForEmployee(dto, user.sub);
  }

  @Post('team')
  createForMyDirectReport(
    @Body() dto: CreateGoalDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.goalsService.createForMyDirectReport(user.sub, dto);
  }

  @Post('bulk-assign')
  @Permissions('goals.manage')
  bulkAssignToDepartment(
    @Body() dto: BulkAssignGoalDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.goalsService.bulkAssignToDepartment(dto, user.sub);
  }

  @Patch(':id')
  @Permissions('goals.manage')
  update(
    @Param('id') id: string,
    @Body() dto: UpdateGoalDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.goalsService.update(id, dto, user.sub, {
      requireOwnDirectReport: false,
    });
  }

  @Patch(':id/team')
  updateAsManager(
    @Param('id') id: string,
    @Body() dto: UpdateGoalDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.goalsService.update(id, dto, user.sub, {
      requireOwnDirectReport: true,
    });
  }

  @Patch(':id/archive')
  @Permissions('goals.manage')
  archive(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.goalsService.archive(id, user.sub, {
      requireOwnDirectReport: false,
    });
  }

  @Patch(':id/team/archive')
  archiveAsManager(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.goalsService.archive(id, user.sub, {
      requireOwnDirectReport: true,
    });
  }
}
