import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { CurrentUser } from '../../authentication/presentation/decorators/current-user.decorator';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { AutomationsService } from '../application/automations.service';
import { UpdateAutomationDto } from '../application/dto/update-automation.dto';
import { AutomationRunTrigger } from '../domain/enums/automation-run-trigger.enum';
import { AutomationType } from '../domain/enums/automation-type.enum';

/** Super-Admin-only, like every Admin Business Management module —
 * `automations.manage` is granted only to Super Admin at seed time. */
@Controller('automations')
@Permissions('automations.manage')
export class AutomationsController {
  constructor(private readonly automationsService: AutomationsService) {}

  @Get()
  getAutomations() {
    return this.automationsService.getAutomations();
  }

  @Patch(':type')
  updateAutomation(
    @Param('type') type: AutomationType,
    @Body() dto: UpdateAutomationDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.automationsService.updateAutomation(type, dto, user.sub);
  }

  @Get('history')
  getHistory(@Query('type') type?: AutomationType) {
    return this.automationsService.getExecutionHistory(type);
  }

  @Post(':type/run')
  runNow(@Param('type') type: AutomationType) {
    return this.automationsService.runAutomation(
      type,
      AutomationRunTrigger.MANUAL,
    );
  }
}
