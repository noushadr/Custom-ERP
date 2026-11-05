import { Controller, Get } from '@nestjs/common';
import { CurrentUser } from '../../authentication/presentation/decorators/current-user.decorator';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { AnnouncementsService } from '../application/announcements.service';

@Controller('announcements')
export class AnnouncementsController {
  constructor(private readonly announcementsService: AnnouncementsService) {}

  /** No @Permissions guard — every authenticated employee sees the same
   * today's-highlights banner, unlike the HR-only "Celebrations" feed in
   * the notification bell. */
  @Get('today')
  getToday(@CurrentUser() user: JwtPayload) {
    return this.announcementsService.getToday(user.sub);
  }
}
