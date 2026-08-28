import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LeadsService } from './application/leads.service';
import { TypeOrmLeadRepository } from './data/repositories/lead.repository';
import { Lead } from './domain/entities/lead.entity';
import { LEAD_REPOSITORY } from './domain/repositories/lead-repository.interface';
import { LeadsController } from './presentation/leads.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Lead])],
  controllers: [LeadsController],
  providers: [
    LeadsService,
    { provide: LEAD_REPOSITORY, useClass: TypeOrmLeadRepository },
  ],
  exports: [LeadsService],
})
export class LeadsModule {}
