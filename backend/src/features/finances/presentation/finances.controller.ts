import { Controller, Get, Query } from '@nestjs/common';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import { FinancesService } from '../application/finances.service';

/** Super-Admin-only, like every Admin Business Management module —
 * `finances.manage` is granted only to Super Admin at seed time. */
@Controller('finances')
@Permissions('finances.manage')
export class FinancesController {
  constructor(private readonly financesService: FinancesService) {}

  @Get('summary')
  getSummary(@Query('from') from?: string, @Query('to') to?: string) {
    return this.financesService.getFinancialSummary(from, to);
  }
}
