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
import { CreateHolidayDto } from '../application/dto/create-holiday.dto';
import { UpdateHolidayDto } from '../application/dto/update-holiday.dto';
import { HolidaysService } from '../application/holidays.service';

@Controller('holidays')
export class HolidaysController {
  constructor(private readonly holidaysService: HolidaysService) {}

  @Get()
  findAll(@Query('year') year?: string) {
    return this.holidaysService.getAll(year ? Number(year) : undefined);
  }

  @Post()
  @Permissions('leave.manage')
  create(@Body() dto: CreateHolidayDto) {
    return this.holidaysService.create(dto);
  }

  @Patch(':id')
  @Permissions('leave.manage')
  update(@Param('id') id: string, @Body() dto: UpdateHolidayDto) {
    return this.holidaysService.update(id, dto);
  }

  @Delete(':id')
  @Permissions('leave.manage')
  @HttpCode(204)
  remove(@Param('id') id: string) {
    return this.holidaysService.remove(id);
  }
}
