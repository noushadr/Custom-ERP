import { Module } from '@nestjs/common';
import { AuthenticationModule } from '../authentication/authentication.module';
import { ClientsModule } from '../clients/clients.module';
import { AgencyReportingService } from './application/agency-reporting.service';
import { AgencyReportingController } from './presentation/agency-reporting.controller';

@Module({
  imports: [AuthenticationModule, ClientsModule],
  controllers: [AgencyReportingController],
  providers: [AgencyReportingService],
})
export class AgencyReportingModule {}
