import { Controller, Get, Query } from '@nestjs/common';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import { AgencyReportingService } from '../application/agency-reporting.service';

/** Super-Admin-only, like every Admin Business Management module —
 * `reports.view` is granted only to Super Admin at seed time. */
@Controller('agency-reporting')
@Permissions('reports.view')
export class AgencyReportingController {
  constructor(private readonly agencyReportingService: AgencyReportingService) {}

  @Get('report')
  getReport(@Query('from') from?: string, @Query('to') to?: string) {
    return this.agencyReportingService.getReport(from, to);
  }
}
