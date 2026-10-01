import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { NotificationsService } from './application/notifications.service';
import { TypeOrmNotificationMutePreferenceRepository } from './data/repositories/notification-mute-preference.repository';
import { TypeOrmNotificationRepository } from './data/repositories/notification.repository';
import { NotificationMutePreference } from './domain/entities/notification-mute-preference.entity';
import { Notification } from './domain/entities/notification.entity';
import { NOTIFICATION_MUTE_PREFERENCE_REPOSITORY } from './domain/repositories/notification-mute-preference-repository.interface';
import { NOTIFICATION_REPOSITORY } from './domain/repositories/notification-repository.interface';
import { NotificationsController } from './presentation/notifications.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Notification, NotificationMutePreference]),
  ],
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    {
      provide: NOTIFICATION_REPOSITORY,
      useClass: TypeOrmNotificationRepository,
    },
    {
      provide: NOTIFICATION_MUTE_PREFERENCE_REPOSITORY,
      useClass: TypeOrmNotificationMutePreferenceRepository,
    },
  ],
  exports: [NotificationsService],
})
export class NotificationsModule {}
