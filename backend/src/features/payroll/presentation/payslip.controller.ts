import { Controller, Get, Param, Res } from '@nestjs/common';
import type { Response } from 'express';
import { CurrentUser } from '../../authentication/presentation/decorators/current-user.decorator';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { PayrollService } from '../application/payroll.service';

/** Self-service payslip access — deliberately a separate controller (not
 * folded into `PayrollController`, whose class-level `@Permissions
 * ('payroll.manage')` guard would block every non-HR/Admin employee) so
 * every employee can view/download their own payslips with no permission
 * needed, identity-scoped server-side exactly like Goals'/Email's `/me`
 * routes. */
@Controller('payslips')
export class PayslipController {
  constructor(private readonly payrollService: PayrollService) {}

  @Get('mine')
  getMine(@CurrentUser() user: JwtPayload) {
    return this.payrollService.getMyPayslips(user.sub);
  }

  @Get('mine/:lineItemId')
  async downloadMine(
    @Param('lineItemId') lineItemId: string,
    @CurrentUser() user: JwtPayload,
    @Res() res: Response,
  ) {
    const { buffer, filename } = await this.payrollService.getMyPayslipPdf(
      user.sub,
      lineItemId,
    );
    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename="${filename}"`,
    });
    res.send(buffer);
  }
}
