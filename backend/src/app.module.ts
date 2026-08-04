import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import configuration from './core/config/configuration';
import { validate } from './core/config/env.validation';
import { DatabaseModule } from './core/database/database.module';
import { AuthenticationModule } from './features/authentication/authentication.module';
import { DepartmentsModule } from './features/departments/departments.module';
import { TeamsModule } from './features/teams/teams.module';
import { EmployeeModule } from './features/employee/employee.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
      validate,
    }),
    DatabaseModule,
    AuthenticationModule,
    DepartmentsModule,
    TeamsModule,
    EmployeeModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
