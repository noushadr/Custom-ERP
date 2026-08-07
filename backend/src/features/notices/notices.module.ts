import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthenticationModule } from '../authentication/authentication.module';
import { EmployeeModule } from '../employee/employee.module';
import { NoticesService } from './application/notices.service';
import { TypeOrmNoticeRepository } from './data/repositories/notice.repository';
import { Notice } from './domain/entities/notice.entity';
import { NOTICE_REPOSITORY } from './domain/repositories/notice-repository.interface';
import { NoticesController } from './presentation/notices.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Notice]),
    AuthenticationModule,
    EmployeeModule,
  ],
  controllers: [NoticesController],
  providers: [
    NoticesService,
    { provide: NOTICE_REPOSITORY, useClass: TypeOrmNoticeRepository },
  ],
})
export class NoticesModule {}
