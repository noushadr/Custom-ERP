import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { NotificationsService } from './application/notifications.service';
import { TypeOrmNotificationRepository } from './data/repositories/notification.repository';
import { Notification } from './domain/entities/notification.entity';
import { NOTIFICATION_REPOSITORY } from './domain/repositories/notification-repository.interface';
import { NotificationsController } from './presentation/notifications.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Notification])],
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    {
      provide: NOTIFICATION_REPOSITORY,
      useClass: TypeOrmNotificationRepository,
    },
  ],
  exports: [NotificationsService],
})
export class NotificationsModule {}
