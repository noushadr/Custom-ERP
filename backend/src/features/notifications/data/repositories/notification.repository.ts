import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification } from '../../domain/entities/notification.entity';
import { NotificationRepository } from '../../domain/repositories/notification-repository.interface';

@Injectable()
export class TypeOrmNotificationRepository implements NotificationRepository {
  constructor(
    @InjectRepository(Notification)
    private readonly repository: Repository<Notification>,
  ) {}

  findForUser(userId: string, unreadOnly: boolean): Promise<Notification[]> {
    return this.repository.find({
      where: unreadOnly
        ? { recipientUserId: userId, isRead: false }
        : { recipientUserId: userId },
      order: { createdAt: 'DESC' },
    });
  }

  findById(id: string): Promise<Notification | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(notification: Notification): Promise<Notification> {
    return this.repository.save(notification);
  }

  async markAllReadForUser(userId: string): Promise<void> {
    await this.repository.update(
      { recipientUserId: userId, isRead: false },
      { isRead: true },
    );
  }
}
