import { Controller, Get } from '@nestjs/common';
import { RolesService } from '../application/roles.service';
import { Permissions } from './decorators/permissions.decorator';

@Controller('permissions')
@Permissions('roles.manage')
export class PermissionsController {
  constructor(private readonly rolesService: RolesService) {}

  @Get()
  findAll() {
    return this.rolesService.listPermissions();
  }
}
