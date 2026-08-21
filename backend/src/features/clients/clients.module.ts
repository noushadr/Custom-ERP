import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthenticationModule } from '../authentication/authentication.module';
import { DepartmentsModule } from '../departments/departments.module';
import { EmployeeModule } from '../employee/employee.module';
import { ClientsService } from './application/clients.service';
import { TypeOrmClientRepository } from './data/repositories/client.repository';
import { TypeOrmProjectRepository } from './data/repositories/project.repository';
import { TypeOrmServiceRepository } from './data/repositories/service.repository';
import { Client } from './domain/entities/client.entity';
import { Project } from './domain/entities/project.entity';
import { Service } from './domain/entities/service.entity';
import { CLIENT_REPOSITORY } from './domain/repositories/client-repository.interface';
import { PROJECT_REPOSITORY } from './domain/repositories/project-repository.interface';
import { SERVICE_REPOSITORY } from './domain/repositories/service-repository.interface';
import { ClientsController } from './presentation/clients.controller';
import { ProjectsController } from './presentation/projects.controller';
import { ServicesController } from './presentation/services.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Client, Service, Project]),
    AuthenticationModule,
    EmployeeModule,
    DepartmentsModule,
  ],
  controllers: [ClientsController, ServicesController, ProjectsController],
  providers: [
    ClientsService,
    { provide: CLIENT_REPOSITORY, useClass: TypeOrmClientRepository },
    { provide: SERVICE_REPOSITORY, useClass: TypeOrmServiceRepository },
    { provide: PROJECT_REPOSITORY, useClass: TypeOrmProjectRepository },
  ],
  exports: [ClientsService],
})
export class ClientsModule {}
