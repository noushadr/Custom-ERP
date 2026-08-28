import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import { CreateFinancialRecordDto } from '../application/dto/create-financial-record.dto';
import { UpdateFinancialRecordDto } from '../application/dto/update-financial-record.dto';
import { FinancialRecordsService } from '../application/financial-records.service';

@Controller('financial-records')
@Permissions('finances.manage')
export class FinancialRecordsController {
  constructor(
    private readonly financialRecordsService: FinancialRecordsService,
  ) {}

  @Get()
  getRecords() {
    return this.financialRecordsService.getRecords();
  }

  @Post()
  createRecord(@Body() dto: CreateFinancialRecordDto) {
    return this.financialRecordsService.createRecord(dto);
  }

  @Patch(':id')
  updateRecord(
    @Param('id') id: string,
    @Body() dto: UpdateFinancialRecordDto,
  ) {
    return this.financialRecordsService.updateRecord(id, dto);
  }
}
