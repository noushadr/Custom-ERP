import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { FinancialRecordsService } from './application/financial-records.service';
import { TypeOrmFinancialRecordRepository } from './data/repositories/financial-record.repository';
import { FinancialRecord } from './domain/entities/financial-record.entity';
import { FINANCIAL_RECORD_REPOSITORY } from './domain/repositories/financial-record-repository.interface';
import { FinancialRecordsController } from './presentation/financial-records.controller';

@Module({
  imports: [TypeOrmModule.forFeature([FinancialRecord])],
  controllers: [FinancialRecordsController],
  providers: [
    FinancialRecordsService,
    {
      provide: FINANCIAL_RECORD_REPOSITORY,
      useClass: TypeOrmFinancialRecordRepository,
    },
  ],
  exports: [FinancialRecordsService],
})
export class FinancialReportsModule {}
