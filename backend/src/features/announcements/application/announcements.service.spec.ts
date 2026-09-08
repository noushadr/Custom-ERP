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
  let noticesService: jest.Mocked<Pick<NoticesService, 'findAll'>>;
  let requestsService: jest.Mocked<
    Pick<RequestsService, 'getCurrentEmployeeOfTheMonth'>
  >;

  beforeEach(() => {
    employeesService = {
      getUpcomingBirthdays: jest.fn().mockResolvedValue([]),
      getUpcomingWorkAnniversaries: jest.fn().mockResolvedValue([]),
    };
    holidaysService = { getAll: jest.fn().mockResolvedValue([]) };
    noticesService = { findAll: jest.fn().mockResolvedValue([]) };
    requestsService = { getCurrentEmployeeOfTheMonth: jest.fn() };

    service = new AnnouncementsService(
      employeesService as unknown as EmployeesService,
      holidaysService as unknown as HolidaysService,
      noticesService as unknown as NoticesService,
      requestsService as unknown as RequestsService,
    );
  });

  describe('getToday', () => {
    it('includes the current Employee of the Month when one is set', async () => {
      requestsService.getCurrentEmployeeOfTheMonth.mockResolvedValue({
        employeeId: 'employee-1',
        fullName: 'Babar Hussain',
        profilePhotoUrl: 'photo.jpg',
        approvedAt: '2026-09-01T00:00:00.000Z',
      });

      const result = await service.getToday();

      expect(result.employeeOfTheMonth).toEqual({
        employeeId: 'employee-1',
        fullName: 'Babar Hussain',
        profilePhotoUrl: 'photo.jpg',
      });
    });

    it('is null when there is no current Employee of the Month', async () => {
      requestsService.getCurrentEmployeeOfTheMonth.mockResolvedValue(null);

      const result = await service.getToday();

      expect(result.employeeOfTheMonth).toBeNull();
    });
  });
});
