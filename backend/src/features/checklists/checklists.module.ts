import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthenticationModule } from '../authentication/authentication.module';
import { ChecklistsService } from './application/checklists.service';
import { TypeOrmChecklistTemplateRepository } from './data/repositories/checklist-template.repository';
import { TypeOrmEmployeeChecklistRepository } from './data/repositories/employee-checklist.repository';
import { ChecklistTemplateItem } from './domain/entities/checklist-template-item.entity';
import { EmployeeChecklistItem } from './domain/entities/employee-checklist-item.entity';
import { CHECKLIST_TEMPLATE_REPOSITORY } from './domain/repositories/checklist-template-repository.interface';
import { EMPLOYEE_CHECKLIST_REPOSITORY } from './domain/repositories/employee-checklist-repository.interface';
import { ChecklistsController } from './presentation/checklists.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([ChecklistTemplateItem, EmployeeChecklistItem]),
    AuthenticationModule,
  ],
  controllers: [ChecklistsController],
  providers: [
    ChecklistsService,
    {
      provide: CHECKLIST_TEMPLATE_REPOSITORY,
      useClass: TypeOrmChecklistTemplateRepository,
    },
    {
      provide: EMPLOYEE_CHECKLIST_REPOSITORY,
      useClass: TypeOrmEmployeeChecklistRepository,
    },
  ],
  exports: [ChecklistsService],
})
export class ChecklistsModule {}
