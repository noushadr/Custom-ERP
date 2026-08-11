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
import { CreateDepartmentDto } from '../application/dto/create-department.dto';
import { UpdateDepartmentDto } from '../application/dto/update-department.dto';
import { DepartmentsService } from '../application/departments.service';

@Controller('departments')
export class DepartmentsController {
  constructor(private readonly departmentsService: DepartmentsService) {}

  @Get()
  findAll(@Query('includeArchived') includeArchived?: string) {
    return this.departmentsService.findAll(includeArchived === 'true');
  }

  @Post()
  @Permissions('departments.manage')
  create(@Body() dto: CreateDepartmentDto) {
    return this.departmentsService.create(dto);
  }

  @Patch(':id')
  @Permissions('departments.manage')
  update(@Param('id') id: string, @Body() dto: UpdateDepartmentDto) {
    return this.departmentsService.update(id, dto);
  }

  @Delete(':id')
  @Permissions('departments.manage')
  @HttpCode(204)
  remove(@Param('id') id: string) {
    return this.departmentsService.remove(id);
  }
}
