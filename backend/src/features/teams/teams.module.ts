import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Team } from './domain/entities/team.entity';
import { TEAM_REPOSITORY } from './domain/repositories/team-repository.interface';
import { TypeOrmTeamRepository } from './data/repositories/team.repository';
import { TeamsService } from './application/teams.service';
import { TeamsController } from './presentation/teams.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Team])],
  controllers: [TeamsController],
  providers: [
    TeamsService,
    { provide: TEAM_REPOSITORY, useClass: TypeOrmTeamRepository },
  ],
  exports: [TeamsService],
})
export class TeamsModule {}
