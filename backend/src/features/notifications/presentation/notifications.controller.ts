import { Controller, Get, Param, Patch, Query } from '@nestjs/common';
import { CurrentUser } from '../../authentication/presentation/decorators/current-user.decorator';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { NotificationsService } from '../application/notifications.service';

/** No `@Permissions()` guard on this controller — every route only ever
 * reads or mutates the caller's own notifications, same pattern as
 * `TasksController`'s `/tasks/me`. */
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  getMine(
    @CurrentUser() user: JwtPayload,
    @Query('unreadOnly') unreadOnly?: string,
  ) {
    return this.notificationsService.getForUser(user.sub, unreadOnly === 'true');
  }

  @Patch(':id/read')
  markRead(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.notificationsService.markRead(id, user.sub);
  }

  @Patch('read-all')
  markAllRead(@CurrentUser() user: JwtPayload) {
    return this.notificationsService.markAllRead(user.sub);
  }
}
