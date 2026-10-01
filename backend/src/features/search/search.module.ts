import { Module } from '@nestjs/common';
import { ClientsModule } from '../clients/clients.module';
import { EmployeeModule } from '../employee/employee.module';
import { KnowledgeBaseModule } from '../knowledge-base/knowledge-base.module';
import { LeadsModule } from '../leads/leads.module';
import { TasksModule } from '../tasks/tasks.module';
import { SearchService } from './application/search.service';
import { SearchController } from './presentation/search.controller';

@Module({
  imports: [
    EmployeeModule,
    TasksModule,
    ClientsModule,
    KnowledgeBaseModule,
    LeadsModule,
  ],
  controllers: [SearchController],
  providers: [SearchService],
})
export class SearchModule {}
