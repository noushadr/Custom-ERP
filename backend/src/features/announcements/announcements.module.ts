import { Module } from '@nestjs/common';
import { EmployeeModule } from '../employee/employee.module';
import { HolidaysModule } from '../holidays/holidays.module';
import { NoticesModule } from '../notices/notices.module';
import { AnnouncementsService } from './application/announcements.service';
import { AnnouncementsController } from './presentation/announcements.controller';

@Module({
  imports: [EmployeeModule, HolidaysModule, NoticesModule],
  controllers: [AnnouncementsController],
  providers: [AnnouncementsService],
})
export class AnnouncementsModule {}
