import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthenticationModule } from '../authentication/authentication.module';
import { EmployeeModule } from '../employee/employee.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { RequestsService } from './application/requests.service';
import { TypeOrmRequestRepository } from './data/repositories/request.repository';
import { EmployeeRequest } from './domain/entities/employee-request.entity';
import { REQUEST_REPOSITORY } from './domain/repositories/request-repository.interface';
import { RequestsController } from './presentation/requests.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([EmployeeRequest]),
    AuthenticationModule,
    EmployeeModule,
    NotificationsModule,
  ],
  controllers: [RequestsController],
  providers: [
    RequestsService,
    { provide: REQUEST_REPOSITORY, useClass: TypeOrmRequestRepository },
  ],
})
export class RequestsModule {}
