import { BadRequestException, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Employee } from '../../employee/domain/entities/employee.entity';
import type { EmployeeRepository } from '../../employee/domain/repositories/employee-repository.interface';
import { EmailAccount } from '../domain/entities/email-account.entity';
import type { EmailAccountRepository } from '../domain/repositories/email-account-repository.interface';
import { EmailService } from './email.service';

const sendMailMock = jest.fn().mockResolvedValue(undefined);
jest.mock('nodemailer', () => ({
  createTransport: jest.fn(() => ({ sendMail: sendMailMock })),
}));

const TEST_KEY =
  '0000000000000000000000000000000000000000000000000000000000000000'.slice(
    0,
    64,
  );

function buildEmployee(overrides: Partial<Employee> = {}): Employee {
  return { id: 'employee-1', userId: 'user-1', ...overrides } as Employee;
}

function buildAccount(overrides: Partial<EmailAccount> = {}): EmailAccount {
  const account = new EmailAccount();
  account.id = 'account-1';
  account.employeeId = 'employee-1';
  account.emailAddress = 'employee@zeracreative.com';
  account.encryptedPassword = '';
  account.smtpHost = 'mail.zeracreative.com';
  account.smtpPort = 587;
  account.imapHost = 'mail.zeracreative.com';
  account.imapPort = 993;
  account.smtpSecure = true;
  return Object.assign(account, overrides);
}

describe('EmailService', () => {
  let service: EmailService;
  let emailAccountRepository: jest.Mocked<EmailAccountRepository>;
  let employeeRepository: jest.Mocked<EmployeeRepository>;
  let config: ConfigService;

  beforeEach(() => {
    sendMailMock.mockClear();
    emailAccountRepository = {
      findByEmployeeId: jest.fn(),
      save: jest.fn((account) => Promise.resolve(account)),
      remove: jest.fn().mockResolvedValue(undefined),
    };
    employeeRepository = {
      findAll: jest.fn(),
      findById: jest.fn(),
      findByUserId: jest.fn(),
      findByReportingManagerId: jest.fn(),
      count: jest.fn(),
      save: jest.fn(),
    };
    config = {
      get: jest.fn().mockReturnValue(TEST_KEY),
    } as unknown as ConfigService;

    service = new EmailService(emailAccountRepository, employeeRepository, config);
  });

  describe('getMyAccount', () => {
    it('returns null when the viewer has no employee profile', async () => {
      employeeRepository.findByUserId.mockResolvedValue(null);
      await expect(service.getMyAccount('user-1')).resolves.toBeNull();
    });

    it('never includes the password in the response', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      emailAccountRepository.findByEmployeeId.mockResolvedValue(
        buildAccount({ encryptedPassword: 'super-secret-cipher' }),
      );

      const result = await service.getMyAccount('user-1');

      expect(result).not.toBeNull();
      expect(JSON.stringify(result)).not.toContain('super-secret-cipher');
      expect(result).not.toHaveProperty('password');
      expect(result).not.toHaveProperty('encryptedPassword');
    });
  });

  describe('setupMyAccount', () => {
    it('throws when the viewer has no employee profile', async () => {
      employeeRepository.findByUserId.mockResolvedValue(null);
      await expect(
        service.setupMyAccount('user-1', {
          emailAddress: 'a@b.com',
          password: 'pw',
          smtpHost: 'mail.b.com',
          imapHost: 'mail.b.com',
        }),
      ).rejects.toThrow(NotFoundException);
    });

    it('encrypts the password at rest, never storing it in plain text', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      emailAccountRepository.findByEmployeeId.mockResolvedValue(null);

      await service.setupMyAccount('user-1', {
        emailAddress: 'employee@zeracreative.com',
        password: 'mailbox-real-password',
        smtpHost: 'mail.zeracreative.com',
        imapHost: 'mail.zeracreative.com',
      });

      const saved = emailAccountRepository.save.mock.calls[0][0];
      expect(saved.encryptedPassword).not.toBe('mailbox-real-password');
      expect(saved.encryptedPassword).not.toContain('mailbox-real-password');
      expect(saved.employeeId).toBe('employee-1');
      expect(saved.smtpPort).toBe(587);
      expect(saved.imapPort).toBe(993);
    });

    it('updates the existing account instead of creating a duplicate', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      const existing = buildAccount();
      emailAccountRepository.findByEmployeeId.mockResolvedValue(existing);

      await service.setupMyAccount('user-1', {
        emailAddress: 'new@zeracreative.com',
        password: 'pw',
        smtpHost: 'mail.zeracreative.com',
        imapHost: 'mail.zeracreative.com',
      });

      const saved = emailAccountRepository.save.mock.calls[0][0];
      expect(saved.id).toBe('account-1');
      expect(saved.emailAddress).toBe('new@zeracreative.com');
    });
  });

  describe('setupForEmployee', () => {
    it('throws when the target employee does not exist', async () => {
      employeeRepository.findById.mockResolvedValue(null);
      await expect(
        service.setupForEmployee('missing-employee', {
          emailAddress: 'a@b.com',
          password: 'pw',
          smtpHost: 'mail.b.com',
          imapHost: 'mail.b.com',
        }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('sendMail', () => {
    it('throws when no mailbox is set up for the viewer', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      emailAccountRepository.findByEmployeeId.mockResolvedValue(null);

      await expect(
        service.sendMail('user-1', {
          to: 'someone@example.com',
          subject: 'Hi',
          body: 'Hello',
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('sends from the viewer own mailbox using their decrypted password', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      const account = buildAccount();
      // Encrypt via the same round-trip setup would use.
      const setupResult = await (async () => {
        emailAccountRepository.findByEmployeeId.mockResolvedValueOnce(null);
        await service.setupMyAccount('user-1', {
          emailAddress: account.emailAddress,
          password: 'mailbox-real-password',
          smtpHost: account.smtpHost,
          imapHost: account.imapHost,
        });
        return emailAccountRepository.save.mock.calls[0][0];
      })();

      emailAccountRepository.findByEmployeeId.mockResolvedValue(setupResult);

      await service.sendMail('user-1', {
        to: 'someone@example.com',
        subject: 'Hi',
        body: 'Hello',
      });

      expect(sendMailMock).toHaveBeenCalledWith(
        expect.objectContaining({
          from: account.emailAddress,
          to: 'someone@example.com',
          subject: 'Hi',
          text: 'Hello',
        }),
      );
    });
  });

  describe('removeMyAccount', () => {
    it('is a no-op when nothing is set up', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      emailAccountRepository.findByEmployeeId.mockResolvedValue(null);
      await service.removeMyAccount('user-1');
      expect(emailAccountRepository.remove).not.toHaveBeenCalled();
    });

    it('removes the existing account', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      const account = buildAccount();
      emailAccountRepository.findByEmployeeId.mockResolvedValue(account);
      await service.removeMyAccount('user-1');
      expect(emailAccountRepository.remove).toHaveBeenCalledWith(account);
    });
  });
});
