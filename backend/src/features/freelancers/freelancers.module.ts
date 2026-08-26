import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthenticationModule } from '../authentication/authentication.module';
import { FreelancersService } from './application/freelancers.service';
import { TypeOrmFreelancerRepository } from './data/repositories/freelancer.repository';
import { Freelancer } from './domain/entities/freelancer.entity';
import { FREELANCER_REPOSITORY } from './domain/repositories/freelancer-repository.interface';
import { FreelancersController } from './presentation/freelancers.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Freelancer]), AuthenticationModule],
  controllers: [FreelancersController],
  providers: [
    FreelancersService,
    { provide: FREELANCER_REPOSITORY, useClass: TypeOrmFreelancerRepository },
  ],
  exports: [FreelancersService, FREELANCER_REPOSITORY],
})
export class FreelancersModule {}
