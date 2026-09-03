import { Controller, Get } from '@nestjs/common';
import { AnnouncementsService } from '../application/announcements.service';

@Controller('announcements')
export class AnnouncementsController {
  constructor(private readonly announcementsService: AnnouncementsService) {}

  /** No @Permissions guard — every authenticated employee sees the same
   * today's-highlights banner, unlike the HR-only "Celebrations" feed in
   * the notification bell. */
  @Get('today')
  getToday() {
    return this.announcementsService.getToday();
  }
}
