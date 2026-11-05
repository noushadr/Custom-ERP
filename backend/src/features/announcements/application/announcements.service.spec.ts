import type { AttendanceService } from '../../attendance/application/attendance.service';
import type { EmployeesService } from '../../employee/application/employees.service';
import type { HolidaysService } from '../../holidays/application/holidays.service';
import type { NoticesService } from '../../notices/application/notices.service';
import type { RequestsService } from '../../requests/application/requests.service';
import { AnnouncementsService } from './announcements.service';

describe('AnnouncementsService', () => {
  let service: AnnouncementsService;
  let employeesService: jest.Mocked<
    Pick<EmployeesService, 'getUpcomingBirthdays' | 'getUpcomingWorkAnniversaries'>
  >;
  let holidaysService: jest.Mocked<Pick<HolidaysService, 'getAll'>>;
  let noticesService: jest.Mocked<Pick<NoticesService, 'findActive'>>;
  let requestsService: jest.Mocked<
    Pick<RequestsService, 'getCurrentEmployeeOfTheMonth'>
  >;
  let attendanceService: jest.Mocked<
    Pick<AttendanceService, 'getWfhAnnouncement'>
  >;

  beforeEach(() => {
    employeesService = {
      getUpcomingBirthdays: jest.fn().mockResolvedValue([]),
      getUpcomingWorkAnniversaries: jest.fn().mockResolvedValue([]),
    };
    holidaysService = { getAll: jest.fn().mockResolvedValue([]) };
    noticesService = { findActive: jest.fn().mockResolvedValue([]) };
    requestsService = { getCurrentEmployeeOfTheMonth: jest.fn() };
    attendanceService = {
      getWfhAnnouncement: jest
        .fn()
        .mockResolvedValue({ today: null, tomorrow: null }),
    };

    service = new AnnouncementsService(
      employeesService as unknown as EmployeesService,
      holidaysService as unknown as HolidaysService,
      noticesService as unknown as NoticesService,
      requestsService as unknown as RequestsService,
      attendanceService as unknown as AttendanceService,
    );
  });

  describe('getToday', () => {
    it('announces a work-from-home day to the viewer, and nothing when there is none', async () => {
      const none = await service.getToday('user-1');
      expect(none.workFromHome).toBeNull();

      attendanceService.getWfhAnnouncement.mockResolvedValue({
        today: { personal: false, note: 'Power cut' },
        tomorrow: null,
      });
      const some = await service.getToday('user-1');
      expect(some.workFromHome).toEqual({
        today: { personal: false, note: 'Power cut' },
        tomorrow: null,
      });
      expect(attendanceService.getWfhAnnouncement).toHaveBeenCalledWith(
        'user-1',
      );
    });

    it('includes the current Employee of the Month when one is set', async () => {
      requestsService.getCurrentEmployeeOfTheMonth.mockResolvedValue({
        employeeId: 'employee-1',
        fullName: 'Babar Hussain',
        profilePhotoUrl: 'photo.jpg',
        approvedAt: '2026-09-01T00:00:00.000Z',
      });

      const result = await service.getToday('user-1');

      expect(result.employeeOfTheMonth).toEqual({
        employeeId: 'employee-1',
        fullName: 'Babar Hussain',
        profilePhotoUrl: 'photo.jpg',
      });
    });

    it('is null when there is no current Employee of the Month', async () => {
      requestsService.getCurrentEmployeeOfTheMonth.mockResolvedValue(null);

      const result = await service.getToday('user-1');

      expect(result.employeeOfTheMonth).toBeNull();
    });
  });
});
