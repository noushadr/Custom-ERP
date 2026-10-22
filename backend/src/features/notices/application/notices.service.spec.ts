import { Employee } from '../../employee/domain/entities/employee.entity';
import type { EmployeeRepository } from '../../employee/domain/repositories/employee-repository.interface';
import { User } from '../../authentication/domain/entities/user.entity';
import type { UserRepository } from '../../authentication/domain/repositories/user-repository.interface';
import { Notice } from '../domain/entities/notice.entity';
import { NoticeDisplayDuration } from '../domain/enums/notice-display-duration.enum';
import type { NoticeRepository } from '../domain/repositories/notice-repository.interface';
import { NoticesService } from './notices.service';

const NOW = new Date('2026-10-22T10:00:00.000Z');
const DAY_MS = 24 * 60 * 60 * 1000;

describe('NoticesService', () => {
  let service: NoticesService;
  let noticeRepository: jest.Mocked<NoticeRepository>;
  let employeeRepository: jest.Mocked<EmployeeRepository>;
  let userRepository: jest.Mocked<UserRepository>;

  beforeEach(() => {
    jest.useFakeTimers({ now: NOW });
    noticeRepository = {
      findAll: jest.fn(),
      findActive: jest.fn(),
      findById: jest.fn(),
      save: jest.fn(),
      remove: jest.fn(),
    };
    employeeRepository = {
      findAll: jest.fn(),
      findById: jest.fn(),
      findByUserId: jest.fn(),
      findByReportingManagerId: jest.fn(),
      count: jest.fn(),
      save: jest.fn(),
    };
    userRepository = {
      findByEmail: jest.fn(),
      findById: jest.fn(),
      findAll: jest.fn(),
      save: jest.fn(),
    };

    service = new NoticesService(
      noticeRepository,
      employeeRepository,
      userRepository,
    );
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  describe('reading', () => {
    it('findActive asks the repository for notices still showing as of now', async () => {
      const notices = [{ id: 'notice-1' }] as never[];
      noticeRepository.findActive.mockResolvedValue(notices);

      await expect(service.findActive()).resolves.toBe(notices);
      expect(noticeRepository.findActive).toHaveBeenCalledWith(NOW);
    });

    it('findAllIncludingExpired returns everything, expired included', async () => {
      const notices = [{ id: 'old' }, { id: 'new' }] as never[];
      noticeRepository.findAll.mockResolvedValue(notices);

      await expect(service.findAllIncludingExpired()).resolves.toBe(notices);
      expect(noticeRepository.findActive).not.toHaveBeenCalled();
    });
  });

  describe('create', () => {
    beforeEach(() => {
      employeeRepository.findByUserId.mockResolvedValue({
        firstName: 'Jane',
        lastName: 'Doe',
      } as Employee);
      noticeRepository.save.mockImplementation((notice) =>
        Promise.resolve(notice),
      );
    });

    it('snapshots the author name from their employee profile', async () => {
      const result = await service.create(
        { title: 'Office closed', body: 'Closed for the holiday.' },
        'user-1',
      );

      expect(result.authorName).toBe('Jane Doe');
      expect(result.authorUserId).toBe('user-1');
      expect(result.title).toBe('Office closed');
    });

    it('derives a display name from the email when there is no employee profile', async () => {
      employeeRepository.findByUserId.mockResolvedValue(null);
      userRepository.findById.mockResolvedValue({
        email: 'admin@zeracreative.com',
      } as User);

      const result = await service.create(
        { title: 'Welcome', body: 'Hello team.' },
        'user-2',
      );

      expect(result.authorName).toBe('Admin');
    });

    it('never expires when no display duration is given (the old behaviour)', async () => {
      const result = await service.create(
        { title: 'Always', body: 'No end date.' },
        'user-1',
      );

      expect(result.expiresAt).toBeNull();
    });

    it('never expires for the explicit Always option', async () => {
      const result = await service.create(
        {
          title: 'Always',
          body: 'No end date.',
          displayDuration: NoticeDisplayDuration.ALWAYS,
        },
        'user-1',
      );

      expect(result.expiresAt).toBeNull();
    });

    it.each([
      [NoticeDisplayDuration.ONE_DAY, 1],
      [NoticeDisplayDuration.THREE_DAYS, 3],
      [NoticeDisplayDuration.ONE_WEEK, 7],
      [NoticeDisplayDuration.TWO_WEEKS, 14],
      [NoticeDisplayDuration.ONE_MONTH, 30],
    ])('expires %s after %d day(s), counted from the server clock', async (displayDuration, days) => {
      const result = await service.create(
        { title: 'Timed', body: 'Temporary.', displayDuration },
        'user-1',
      );

      expect(result.expiresAt).toEqual(new Date(NOW.getTime() + days * DAY_MS));
    });
  });

  describe('update', () => {
    function existingNotice(overrides: Partial<Notice> = {}): Notice {
      return {
        id: 'notice-1',
        title: 'Old title',
        body: 'Old body',
        authorName: 'Jane Doe',
        expiresAt: null,
        ...overrides,
      } as Notice;
    }

    beforeEach(() => {
      noticeRepository.save.mockImplementation((n) => Promise.resolve(n));
    });

    it('applies only the fields provided', async () => {
      noticeRepository.findById.mockResolvedValue(existingNotice());

      const result = await service.update('notice-1', { title: 'New title' });

      expect(result.title).toBe('New title');
      expect(result.body).toBe('Old body');
      expect(result.authorName).toBe('Jane Doe');
    });

    it('leaves the expiry alone when no display duration is sent', async () => {
      const expiresAt = new Date(NOW.getTime() + 2 * DAY_MS);
      noticeRepository.findById.mockResolvedValue(
        existingNotice({ expiresAt }),
      );

      const result = await service.update('notice-1', { title: 'New title' });

      expect(result.expiresAt).toBe(expiresAt);
    });

    it('restarts the window from now, so an expired notice can be brought back', async () => {
      noticeRepository.findById.mockResolvedValue(
        existingNotice({ expiresAt: new Date(NOW.getTime() - 3 * DAY_MS) }),
      );

      const result = await service.update('notice-1', {
        displayDuration: NoticeDisplayDuration.ONE_WEEK,
      });

      expect(result.expiresAt).toEqual(new Date(NOW.getTime() + 7 * DAY_MS));
    });

    it('can switch a timed notice to Always', async () => {
      noticeRepository.findById.mockResolvedValue(
        existingNotice({ expiresAt: new Date(NOW.getTime() + DAY_MS) }),
      );

      const result = await service.update('notice-1', {
        displayDuration: NoticeDisplayDuration.ALWAYS,
      });

      expect(result.expiresAt).toBeNull();
    });

    it('does not store the duration preset itself on the notice', async () => {
      noticeRepository.findById.mockResolvedValue(existingNotice());

      const result = await service.update('notice-1', {
        displayDuration: NoticeDisplayDuration.ONE_DAY,
      });

      expect(result).not.toHaveProperty('displayDuration');
    });

    it('throws NotFoundException when the notice does not exist', async () => {
      noticeRepository.findById.mockResolvedValue(null);

      await expect(
        service.update('missing', { title: 'New title' }),
      ).rejects.toThrow('Notice not found');
      expect(noticeRepository.save).not.toHaveBeenCalled();
    });
  });

  describe('delete', () => {
    it('removes the notice when it exists', async () => {
      const notice = { id: 'notice-1' } as never;
      noticeRepository.findById.mockResolvedValue(notice);

      await service.delete('notice-1');

      expect(noticeRepository.remove).toHaveBeenCalledWith(notice);
    });

    it('throws NotFoundException when the notice does not exist', async () => {
      noticeRepository.findById.mockResolvedValue(null);

      await expect(service.delete('missing')).rejects.toThrow(
        'Notice not found',
      );
      expect(noticeRepository.remove).not.toHaveBeenCalled();
    });
  });
});
