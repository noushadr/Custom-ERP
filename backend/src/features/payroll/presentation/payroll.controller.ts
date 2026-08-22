import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { CurrentUser } from '../../authentication/presentation/decorators/current-user.decorator';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { GeneratePayrollRunDto } from '../application/dto/generate-payroll-run.dto';
import { UpdatePayrollLineItemDto } from '../application/dto/update-payroll-line-item.dto';
import { PayrollService } from '../application/payroll.service';

/** Super-Admin-only, like every Admin Business Management module —
 * `payroll.manage` is granted only to Super Admin at seed time. */
@Controller('payroll')
@Permissions('payroll.manage')
export class PayrollController {
  constructor(private readonly payrollService: PayrollService) {}

  @Get('runs')
  getRuns() {
    return this.payrollService.getRuns();
  }

  @Post('runs')
  generateRun(
    @Body() dto: GeneratePayrollRunDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.payrollService.generateRun(dto, user.sub);
  }

  @Get('runs/:id')
  getRun(@Param('id') id: string) {
    return this.payrollService.getRun(id);
  }

  @Patch('runs/:runId/line-items/:lineItemId')
  updateLineItem(
    @Param('runId') runId: string,
    @Param('lineItemId') lineItemId: string,
    @Body() dto: UpdatePayrollLineItemDto,
  ) {
    return this.payrollService.updateLineItem(runId, lineItemId, dto);
  }

  @Post('runs/:id/finalize')
  finalizeRun(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.payrollService.finalizeRun(id, user.sub);
  }

  @Post('runs/:id/pay')
  payRun(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.payrollService.payRun(id, user.sub);
  }
}
