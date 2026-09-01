import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Employee } from '../../employee/domain/entities/employee.entity';
import type { EmployeesService } from '../../employee/application/employees.service';
import type { EmployeeRepository } from '../../employee/domain/repositories/employee-repository.interface';
import type { UserRepository } from '../../authentication/domain/repositories/user-repository.interface';
import { EmployeeRequest } from '../domain/entities/employee-request.entity';
import { RequestKind } from '../domain/enums/request-kind.enum';
import { RequestStatus } from '../domain/enums/request-status.enum';
import type { RequestRepository } from '../domain/repositories/request-repository.interface';
import { RequestsService } from './requests.service';

function buildEmployee(overrides: Partial<Employee> = {}): Employee {
  return {
    id: 'employee-1',
    firstName: 'Jane',
    lastName: 'Doe',
    reportingManagerId: 'manager-1',
    ...overrides,
  } as Employee;
}

function buildRequest(
  overrides: Partial<EmployeeRequest> = {},
): EmployeeRequest {
  return {
    id: 'request-1',
    employeeId: 'employee-1',
    employee: buildEmployee(),
    subject: 'New laptop',
    description: 'Current one is broken.',
    status: RequestStatus.SUBMITTED,
    createdAt: new Date('2026-01-01T00:00:00Z'),
    ...overrides,
  } as EmployeeRequest;
}

describe('RequestsService', () => {
  let service: RequestsService;
  let requestRepository: jest.Mocked<RequestRepository>;
  let employeeRepository: jest.Mocked<EmployeeRepository>;
  let userRepository: jest.Mocked<UserRepository>;
  let employeesService: jest.Mocked<
    Pick<
      EmployeesService,
      'previewProfileChanges' | 'applyApprovedProfileChange'
    >
  >;

  beforeEach(() => {
    requestRepository = {
      findById: jest.fn(),
      findByEmployeeId: jest.fn(),
      findByStatus: jest.fn(),
      save: jest.fn(),
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
    employeesService = {
      previewProfileChanges: jest.fn(),
      applyApprovedProfileChange: jest.fn(),
    };

    service = new RequestsService(
      requestRepository,
      employeeRepository,
      userRepository,
      employeesService as unknown as EmployeesService,
    );
  });

  describe('submit', () => {
    it('throws when the caller has no employee profile', async () => {
      employeeRepository.findByUserId.mockResolvedValue(null);

      await expect(
        service.submit('user-1', { subject: 'x', description: 'y' }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('creates a SUBMITTED request for the caller', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      requestRepository.save.mockResolvedValue(buildRequest());
      requestRepository.findById.mockResolvedValue(buildRequest());

      const result = await service.submit('user-1', {
        subject: 'New laptop',
        description: 'Current one is broken.',
      });

      expect(requestRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          employeeId: 'employee-1',
          status: RequestStatus.SUBMITTED,
        }),
      );
      expect(result.status).toBe(RequestStatus.SUBMITTED);
      expect(result.requesterName).toBe('Jane Doe');
    });
  });

  describe('submitProfileChangeRequest', () => {
    it('throws BadRequestException when nothing actually changed', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      employeesService.previewProfileChanges.mockResolvedValue([]);

      await expect(
        service.submitProfileChangeRequest('user-1', { phoneNumber: '123' }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('creates a MANAGER_APPROVED request carrying the proposed changes', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      employeesService.previewProfileChanges.mockResolvedValue([
        { fieldLabel: 'Phone Number', oldValue: null, newValue: '123' },
      ]);
      requestRepository.save.mockImplementation((r) => Promise.resolve(r));
      requestRepository.findById.mockImplementation((id) =>
        Promise.resolve(
          buildRequest({
            id,
            status: RequestStatus.MANAGER_APPROVED,
            kind: RequestKind.PROFILE_CHANGE,
          }),
        ),
      );

      const result = await service.submitProfileChangeRequest('user-1', {
        phoneNumber: '123',
      });

      expect(requestRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          employeeId: 'employee-1',
          kind: RequestKind.PROFILE_CHANGE,
          status: RequestStatus.MANAGER_APPROVED,
          payload: { phoneNumber: '123' },
        }),
      );
      expect(result.status).toBe(RequestStatus.MANAGER_APPROVED);
    });
  });

  describe('findPendingManagerApproval', () => {
    it('only returns submitted requests reporting to this manager', async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'manager-1' }),
      );
      requestRepository.findByStatus.mockResolvedValue([
        buildRequest({ id: 'request-1' }),
        buildRequest({
          id: 'request-2',
          employee: buildEmployee({ reportingManagerId: 'someone-else' }),
        }),
      ]);

      const result = await service.findPendingManagerApproval('user-1');

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('request-1');
    });
  });

  describe('approveAsManager', () => {
    it('throws NotFoundException when the request is missing', async () => {
      requestRepository.findById.mockResolvedValue(null);

      await expect(
        service.approveAsManager('missing', 'user-1'),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('throws BadRequestException when the request is not pending manager approval', async () => {
      requestRepository.findById.mockResolvedValue(
        buildRequest({ status: RequestStatus.COMPLETED }),
      );

      await expect(
        service.approveAsManager('request-1', 'user-1'),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it("throws ForbiddenException when the caller isn't the reporting manager", async () => {
      requestRepository.findById.mockResolvedValue(buildRequest());
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'someone-else' }),
      );

      await expect(
        service.approveAsManager('request-1', 'user-1'),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('approves and stamps the manager decision', async () => {
      requestRepository.findById.mockResolvedValue(buildRequest());
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'manager-1', firstName: 'Nauman', lastName: 'M' }),
      );
      requestRepository.save.mockImplementation((r) => Promise.resolve(r));

      const result = await service.approveAsManager('request-1', 'user-1');

      expect(result.status).toBe(RequestStatus.MANAGER_APPROVED);
      expect(result.managerDecisionByName).toBe('Nauman M');
      expect(result.managerDecisionAt).not.toBeNull();
    });
  });

  describe('approveAsHr', () => {
    it('throws BadRequestException when not yet manager-approved', async () => {
      requestRepository.findById.mockResolvedValue(
        buildRequest({ status: RequestStatus.SUBMITTED }),
      );

      await expect(
        service.approveAsHr('request-1', 'hr-1'),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('completes the request and stamps the HR decision', async () => {
      requestRepository.findById.mockResolvedValue(
        buildRequest({ status: RequestStatus.MANAGER_APPROVED }),
      );
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ firstName: 'Zahra', lastName: 'Shiraz' }),
      );
      requestRepository.save.mockImplementation((r) => Promise.resolve(r));

      const result = await service.approveAsHr('request-1', 'hr-1');

      expect(result.status).toBe(RequestStatus.COMPLETED);
      expect(result.hrDecisionByName).toBe('Zahra Shiraz');
    });

    it('applies the payload to the employee record for a PROFILE_CHANGE request', async () => {
      requestRepository.findById.mockResolvedValue(
        buildRequest({
          status: RequestStatus.MANAGER_APPROVED,
          kind: RequestKind.PROFILE_CHANGE,
          payload: { phoneNumber: '123' },
        }),
      );
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      requestRepository.save.mockImplementation((r) => Promise.resolve(r));

      await service.approveAsHr('request-1', 'hr-1');

      expect(employeesService.applyApprovedProfileChange).toHaveBeenCalledWith(
        'employee-1',
        { phoneNumber: '123' },
      );
    });

    it('does not touch the employee record for a non-PROFILE_CHANGE request', async () => {
      requestRepository.findById.mockResolvedValue(
        buildRequest({ status: RequestStatus.MANAGER_APPROVED }),
      );
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      requestRepository.save.mockImplementation((r) => Promise.resolve(r));

      await service.approveAsHr('request-1', 'hr-1');

      expect(
        employeesService.applyApprovedProfileChange,
      ).not.toHaveBeenCalled();
    });
  });

  describe('rejectAsManager', () => {
    it('rejects with the given reason', async () => {
      requestRepository.findById.mockResolvedValue(buildRequest());
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'manager-1' }),
      );
      requestRepository.save.mockImplementation((r) => Promise.resolve(r));

      const result = await service.rejectAsManager(
        'request-1',
        'user-1',
        'No budget this quarter',
      );

      expect(result.status).toBe(RequestStatus.REJECTED);
      expect(result.rejectionReason).toBe('No budget this quarter');
    });
  });
});
