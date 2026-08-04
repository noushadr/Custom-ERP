import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { CurrentUser } from '../../authentication/presentation/decorators/current-user.decorator';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { InviteEmployeeDto } from '../application/dto/invite-employee.dto';
import { UpdateEmployeeDto } from '../application/dto/update-employee.dto';
import { UpdateMyProfileDto } from '../application/dto/update-my-profile.dto';
import { EmployeesService } from '../application/employees.service';

@Controller('employees')
export class EmployeesController {
  constructor(private readonly employeesService: EmployeesService) {}

  @Post('invite')
  @Permissions('employees.manage')
  invite(@Body() dto: InviteEmployeeDto) {
    return this.employeesService.invite(dto);
  }

  @Get()
  @Permissions('employees.read')
  findAll() {
    return this.employeesService.findAll();
  }

  @Get('me')
  findMe(@CurrentUser() user: JwtPayload) {
    return this.employeesService.findByUserId(user.sub);
  }

  @Patch('me')
  updateMe(@CurrentUser() user: JwtPayload, @Body() dto: UpdateMyProfileDto) {
    return this.employeesService.updateSelf(user.sub, dto);
  }

  @Get(':id')
  @Permissions('employees.read')
  findOne(@Param('id') id: string) {
    return this.employeesService.findById(id);
  }

  @Patch(':id')
  @Permissions('employees.manage')
  update(@Param('id') id: string, @Body() dto: UpdateEmployeeDto) {
    return this.employeesService.update(id, dto);
  }
}
