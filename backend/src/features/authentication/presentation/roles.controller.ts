import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
} from '@nestjs/common';
import { CreateRoleDto } from '../application/dto/create-role.dto';
import { UpdateRoleDto } from '../application/dto/update-role.dto';
import { RolesService } from '../application/roles.service';
import { CurrentUser } from './decorators/current-user.decorator';
import { Permissions } from './decorators/permissions.decorator';
import type { JwtPayload } from './strategies/jwt.strategy';

@Controller('roles')
@Permissions('roles.manage')
export class RolesController {
  constructor(private readonly rolesService: RolesService) {}

  @Get()
  findAll() {
    return this.rolesService.listRoles();
  }

  @Post()
  create(@Body() dto: CreateRoleDto, @CurrentUser() caller: JwtPayload) {
    return this.rolesService.createRole(dto, caller);
  }

  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() dto: UpdateRoleDto,
    @CurrentUser() caller: JwtPayload,
  ) {
    return this.rolesService.updateRole(id, dto, caller);
  }

  @Delete(':id')
  @HttpCode(204)
  remove(@Param('id') id: string) {
    return this.rolesService.deleteRole(id);
  }
}
