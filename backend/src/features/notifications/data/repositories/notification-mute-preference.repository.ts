import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotificationMutePreference } from '../../domain/entities/notification-mute-preference.entity';
import { NotificationCategory } from '../../domain/enums/notification-category.enum';
import { NotificationMutePreferenceRepository } from '../../domain/repositories/notification-mute-preference-repository.interface';

@Injectable()
export class TypeOrmNotificationMutePreferenceRepository implements NotificationMutePreferenceRepository {
  constructor(
    @InjectRepository(NotificationMutePreference)
    private readonly repository: Repository<NotificationMutePreference>,
  ) {}

  async findCategoriesForUser(userId: string): Promise<NotificationCategory[]> {
    const rows = await this.repository.find({ where: { userId } });
    return rows.map((row) => row.category);
  }

  async isMuted(
    userId: string,
    category: NotificationCategory,
  ): Promise<boolean> {
    const row = await this.repository.findOne({
      where: { userId, category },
    });
    return row !== null;
  }

  async mute(userId: string, category: NotificationCategory): Promise<void> {
    const existing = await this.repository.findOne({
      where: { userId, category },
    });
    if (existing) return;
    const preference = new NotificationMutePreference();
    preference.userId = userId;
    preference.category = category;
    await this.repository.save(preference);
  }

  async unmute(userId: string, category: NotificationCategory): Promise<void> {
    await this.repository.delete({ userId, category });
  }
}
