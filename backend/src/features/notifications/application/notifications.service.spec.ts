import { NotFoundException } from '@nestjs/common';
import { Notification } from '../domain/entities/notification.entity';
import { NotificationLinkTarget } from '../domain/enums/notification-link-target.enum';
import type { NotificationRepository } from '../domain/repositories/notification-repository.interface';
import { NotificationsService } from './notifications.service';

function buildNotification(overrides: Partial<Notification> = {}): Notification {
  return {
    id: 'notification-1',
    recipientUserId: 'user-1',
    message: 'Something happened',
    linkTarget: null,
    linkEntityId: null,
    isRead: false,
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    updatedAt: new Date('2026-01-01T00:00:00.000Z'),
    ...overrides,
  } as Notification;
}

describe('NotificationsService', () => {
  let service: NotificationsService;
  let notificationRepository: jest.Mocked<NotificationRepository>;

  beforeEach(() => {
    notificationRepository = {
      findForUser: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      save: jest.fn((n) =>
        Promise.resolve({
          ...n,
          id: n.id ?? 'notification-1',
          createdAt: n.createdAt ?? new Date('2026-01-01T00:00:00.000Z'),
          updatedAt: new Date('2026-01-01T00:00:00.000Z'),
        } as Notification),
      ),
      markAllReadForUser: jest.fn().mockResolvedValue(undefined),
    };
    service = new NotificationsService(notificationRepository);
  });

  it('creates a notification with the given link target and entity id', async () => {
    const result = await service.create({
      recipientUserId: 'user-1',
      message: 'Your task is due soon',
      linkTarget: NotificationLinkTarget.TASKS,
      linkEntityId: 'task-1',
    });

    expect(result.recipientUserId).toBe('user-1');
    expect(result.linkTarget).toBe(NotificationLinkTarget.TASKS);
    expect(result.linkEntityId).toBe('task-1');
    expect(result.isRead).toBe(false);
  });

  it('defaults linkTarget/linkEntityId to null when omitted', async () => {
    const result = await service.create({
      recipientUserId: 'user-1',
      message: 'Leave balances were reset',
    });

    expect(result.linkTarget).toBeNull();
    expect(result.linkEntityId).toBeNull();
  });

  it('returns only the requesting user\'s notifications, newest-first per the repository', async () => {
    notificationRepository.findForUser.mockResolvedValue([buildNotification()]);

    const result = await service.getForUser('user-1', false);

    expect(notificationRepository.findForUser).toHaveBeenCalledWith('user-1', false);
    expect(result).toHaveLength(1);
  });

  describe('markRead', () => {
    it('marks a notification read for its owner', async () => {
      notificationRepository.findById.mockResolvedValue(
        buildNotification({ isRead: false }),
      );

      const result = await service.markRead('notification-1', 'user-1');

      expect(result.isRead).toBe(true);
    });

    it('throws NotFoundException for a notification belonging to someone else', async () => {
      notificationRepository.findById.mockResolvedValue(
        buildNotification({ recipientUserId: 'someone-else' }),
      );

      await expect(
        service.markRead('notification-1', 'user-1'),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('throws NotFoundException when the notification does not exist', async () => {
      notificationRepository.findById.mockResolvedValue(null);
      await expect(
        service.markRead('missing', 'user-1'),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  it('marks all of a user\'s notifications read', async () => {
    await service.markAllRead('user-1');
    expect(notificationRepository.markAllReadForUser).toHaveBeenCalledWith('user-1');
  });
});
