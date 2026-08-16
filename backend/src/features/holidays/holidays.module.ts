import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TypeOrmHolidayRepository } from './data/repositories/holiday.repository';
import { Holiday } from './domain/entities/holiday.entity';
import { HOLIDAY_REPOSITORY } from './domain/repositories/holiday-repository.interface';
import { HolidaysController } from './presentation/holidays.controller';
import { HolidaysService } from './application/holidays.service';

@Module({
  imports: [TypeOrmModule.forFeature([Holiday])],
  controllers: [HolidaysController],
  providers: [
    HolidaysService,
    { provide: HOLIDAY_REPOSITORY, useClass: TypeOrmHolidayRepository },
  ],
  exports: [HolidaysService],
})
export class HolidaysModule {}
