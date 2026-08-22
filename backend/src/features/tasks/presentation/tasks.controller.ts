import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { CurrentUser } from '../../authentication/presentation/decorators/current-user.decorator';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { CreateTaskCommentDto } from '../application/dto/create-task-comment.dto';
import { CreateTaskDto } from '../application/dto/create-task.dto';
import { UpdateTaskStatusDto } from '../application/dto/update-task-status.dto';
import { UpdateTaskDto } from '../application/dto/update-task.dto';
import { TasksService } from '../application/tasks.service';

const PERMISSION = 'tasks.manage';

// No route in this controller carries a @Permissions() guard: every action
// is open to any authenticated user, with TasksService enforcing the
// three-tier authorization (tasks.manage override / department-head /
// self) per-request — the same pattern Leave's manager-approval routes use,
// since a department head's authority isn't a permission flag at all.
@Controller('tasks')
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  @Get('me')
  getMyTasks(@CurrentUser() user: JwtPayload) {
    return this.tasksService.getMyTasks(user.sub);
  }

  @Get('assigned-by-me')
  getTasksAssignedByMe(@CurrentUser() user: JwtPayload) {
    return this.tasksService.getTasksAssignedByMe(user.sub);
  }

  @Get('team')
  getTeamTasks(@CurrentUser() user: JwtPayload) {
    const actorHasOverride = user.permissions.includes(PERMISSION);
    return this.tasksService.getTeamTasks(user.sub, actorHasOverride);
  }

  /** Clients & Projects module's view of "which tasks belong to this
   * project" — gated to clients.manage, unrelated to a linked task's own
   * visibility for its assignee (unchanged, still governed by the normal
   * three-tier rules above). */
  @Get('by-project/:projectId')
  @Permissions('clients.manage')
  getTasksByProject(@Param('projectId') projectId: string) {
    return this.tasksService.getTasksByProject(projectId);
  }

  @Post()
  createTask(@Body() dto: CreateTaskDto, @CurrentUser() user: JwtPayload) {
    const actorHasOverride = user.permissions.includes(PERMISSION);
    return this.tasksService.createTask(dto, user.sub, actorHasOverride);
  }

  // Must come before @Get(':id') — otherwise "history"/"comments" would be
  // captured as the :id parameter instead of matching these routes.
  @Get(':id/history')
  getHistory(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    const actorHasOverride = user.permissions.includes(PERMISSION);
    return this.tasksService.getHistory(id, user.sub, actorHasOverride);
  }

  @Get(':id/comments')
  getComments(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    const actorHasOverride = user.permissions.includes(PERMISSION);
    return this.tasksService.getComments(id, user.sub, actorHasOverride);
  }

  @Post(':id/comments')
  addComment(
    @Param('id') id: string,
    @Body() dto: CreateTaskCommentDto,
    @CurrentUser() user: JwtPayload,
  ) {
    const actorHasOverride = user.permissions.includes(PERMISSION);
    return this.tasksService.addComment(id, dto, user.sub, actorHasOverride);
  }

  @Patch(':id/status')
  updateStatus(
    @Param('id') id: string,
    @Body() dto: UpdateTaskStatusDto,
    @CurrentUser() user: JwtPayload,
  ) {
    const actorHasOverride = user.permissions.includes(PERMISSION);
    return this.tasksService.updateStatus(id, dto, user.sub, actorHasOverride);
  }

  @Get(':id')
  getTask(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    const actorHasOverride = user.permissions.includes(PERMISSION);
    return this.tasksService.getTaskForActor(id, user.sub, actorHasOverride);
  }

  @Patch(':id')
  updateTask(
    @Param('id') id: string,
    @Body() dto: UpdateTaskDto,
    @CurrentUser() user: JwtPayload,
  ) {
    const actorHasOverride = user.permissions.includes(PERMISSION);
    return this.tasksService.updateTask(id, dto, user.sub, actorHasOverride);
  }
}
