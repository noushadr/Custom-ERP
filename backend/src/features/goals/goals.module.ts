import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthenticationModule } from '../authentication/authentication.module';
import { EmployeeModule } from '../employee/employee.module';
import { GoalsService } from './application/goals.service';
import { TypeOrmGoalRepository } from './data/repositories/goal.repository';
import { EmployeeGoal } from './domain/entities/employee-goal.entity';
import { GOAL_REPOSITORY } from './domain/repositories/goal-repository.interface';
import { GoalsController } from './presentation/goals.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([EmployeeGoal]),
    AuthenticationModule,
    EmployeeModule,
  ],
  controllers: [GoalsController],
  providers: [
    GoalsService,
    { provide: GOAL_REPOSITORY, useClass: TypeOrmGoalRepository },
  ],
})
export class GoalsModule {}
