import { Body, Controller, Get, Post } from '@nestjs/common';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import { CreateDepartmentDto } from '../application/dto/create-department.dto';
import { DepartmentsService } from '../application/departments.service';

@Controller('departments')
export class DepartmentsController {
  constructor(private readonly departmentsService: DepartmentsService) {}

  @Get()
  findAll() {
    return this.departmentsService.findAll();
  }

  @Post()
  @Permissions('departments.manage')
  create(@Body() dto: CreateDepartmentDto) {
    return this.departmentsService.create(dto);
  }
}
