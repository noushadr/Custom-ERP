import { Employee } from '../../employee/domain/entities/employee.entity';
import type { EmployeeRepository } from '../../employee/domain/repositories/employee-repository.interface';
import { User } from '../../authentication/domain/entities/user.entity';
import type { UserRepository } from '../../authentication/domain/repositories/user-repository.interface';
import type { NoticeRepository } from '../domain/repositories/notice-repository.interface';
import { NoticesService } from './notices.service';

describe('NoticesService', () => {
  let service: NoticesService;
  let noticeRepository: jest.Mocked<NoticeRepository>;
  let employeeRepository: jest.Mocked<EmployeeRepository>;
  let userRepository: jest.Mocked<UserRepository>;

  beforeEach(() => {
    noticeRepository = {
      findAll: jest.fn(),
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

  describe('findAll', () => {
    it('delegates to the repository', async () => {
      const notices = [{ id: 'notice-1' }] as never[];
      noticeRepository.findAll.mockResolvedValue(notices);

      await expect(service.findAll()).resolves.toBe(notices);
    });
  });

  describe('create', () => {
    it('snapshots the author name from their employee profile', async () => {
      employeeRepository.findByUserId.mockResolvedValue({
        firstName: 'Jane',
        lastName: 'Doe',
      } as Employee);
      noticeRepository.save.mockImplementation((notice) =>
        Promise.resolve(notice),
      );

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
      noticeRepository.save.mockImplementation((notice) =>
        Promise.resolve(notice),
      );

      const result = await service.create(
        { title: 'Welcome', body: 'Hello team.' },
        'user-2',
      );

      expect(result.authorName).toBe('Admin');
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
