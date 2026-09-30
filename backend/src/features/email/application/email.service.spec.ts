import { BadRequestException, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { encryptCredential } from '../../../core/crypto/credential-crypto.util';
import { Employee } from '../../employee/domain/entities/employee.entity';
import type { EmployeeRepository } from '../../employee/domain/repositories/employee-repository.interface';
import { EmailAccount } from '../domain/entities/email-account.entity';
import type { EmailAccountRepository } from '../domain/repositories/email-account-repository.interface';
import type { InboxMessageResponse } from './inbox-message-response.interface';
import { EmailService } from './email.service';

const sendMailMock = jest
  .fn<Promise<void>, [{ raw: Buffer }]>()
  .mockResolvedValue(undefined);
jest.mock('nodemailer', () => ({
  createTransport: jest.fn(() => ({ sendMail: sendMailMock })),
}));

const mockImapClient = {
  connect: jest.fn().mockResolvedValue(undefined),
  getMailboxLock: jest
    .fn()
    .mockResolvedValue({ release: jest.fn(), path: 'INBOX' }),
  search: jest.fn(),
  fetch: jest.fn(),
  list: jest.fn().mockResolvedValue([]),
  download: jest.fn(),
  append: jest.fn().mockResolvedValue(undefined),
  logout: jest.fn().mockResolvedValue(undefined),
};
jest.mock('imapflow', () => ({
  ImapFlow: jest.fn().mockImplementation(() => mockImapClient),
}));

function fetchYielding(
  messages: {
    uid: number;
    from?: string;
    to?: string;
    subject?: string;
    date?: Date;
    seen?: boolean;
  }[],
) {
  return async function* () {
    await Promise.resolve();
    for (const m of messages) {
      yield {
        uid: m.uid,
        envelope: {
          from: m.from ? [{ address: m.from, name: null }] : [],
          to: m.to ? [{ address: m.to, name: null }] : [],
          subject: m.subject ?? 'Hello',
          date: m.date ?? new Date(),
        },
        flags: new Set(m.seen ? ['\\Seen'] : []),
      };
    }
  };
}

function rawMessageDownload(text: string) {
  const raw = Buffer.from(
    `From: a@x.com\r\nTo: b@x.com\r\nSubject: Hi\r\n\r\n${text}`,
  );
  return {
    content: (async function* () {
      await Promise.resolve();
      yield raw;
    })(),
  };
}

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
    mockImapClient.connect.mockClear();
    mockImapClient.getMailboxLock.mockClear();
    mockImapClient.search.mockReset();
    mockImapClient.fetch.mockReset();
    mockImapClient.list.mockReset().mockResolvedValue([]);
    mockImapClient.download.mockReset();
    mockImapClient.append.mockClear();
    mockImapClient.logout.mockClear();
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

    service = new EmailService(
      emailAccountRepository,
      employeeRepository,
      config,
    );
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

      // Sent as a single pre-built raw MIME buffer (so the exact bytes SMTP
      // sends match what gets APPENDed to Sent) rather than separate
      // from/to/subject/text fields.
      const expectedRawCall: { raw: unknown } = {
        raw: expect.any(Buffer) as unknown,
      };
      expect(sendMailMock).toHaveBeenCalledWith(
        expect.objectContaining(expectedRawCall),
      );
      const [[sentMessage]] = sendMailMock.mock.calls;
      const rawArg: Buffer = sentMessage.raw;
      const rawText = rawArg.toString('utf8');
      expect(rawText).toContain(account.emailAddress);
      expect(rawText).toContain('someone@example.com');
      expect(rawText).toContain('Hi');
      expect(rawText).toContain('Hello');
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

  describe('listMessages', () => {
    beforeEach(() => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      emailAccountRepository.findByEmployeeId.mockResolvedValue(
        buildAccount({
          encryptedPassword: encryptCredential('mailbox-password', TEST_KEY),
        }),
      );
    });

    it('searches the inbox since the given months-back cutoff and returns newest first', async () => {
      mockImapClient.search.mockResolvedValue([1, 2, 3]);
      mockImapClient.fetch.mockImplementation(
        fetchYielding([
          { uid: 1, from: 'a@x.com', date: new Date('2026-01-01') },
          { uid: 2, from: 'b@x.com', date: new Date('2026-03-01') },
          { uid: 3, from: 'c@x.com', date: new Date('2026-02-01') },
        ]),
      );

      const result: InboxMessageResponse[] = await service.listMessages(
        'user-1',
        'inbox',
        6,
        200,
      );

      expect(mockImapClient.getMailboxLock).toHaveBeenCalledWith('INBOX');

      // `expect.any()` is loosely typed by @jest/expect.
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      const expectedSearch: { since: Date } = { since: expect.any(Date) };
      expect(mockImapClient.search).toHaveBeenCalledWith(expectedSearch, {
        uid: true,
      });
      expect(result.map((m) => m.uid)).toEqual([2, 3, 1]);
    });

    it('caps the fetched messages to the most recent [limit]', async () => {
      mockImapClient.search.mockResolvedValue([1, 2, 3, 4, 5]);
      mockImapClient.fetch.mockImplementation(
        fetchYielding([
          { uid: 4, date: new Date('2026-01-01') },
          { uid: 5, date: new Date('2026-01-02') },
        ]),
      );

      await service.listMessages('user-1', 'inbox', 6, 2);

      expect(mockImapClient.fetch).toHaveBeenCalledWith(
        [4, 5],
        { envelope: true, flags: true },
        { uid: true },
      );
    });

    it('resolves the Sent folder via the server-advertised special-use flag', async () => {
      mockImapClient.list.mockResolvedValue([
        { path: 'INBOX', specialUse: undefined },
        { path: 'INBOX.Sent', specialUse: '\\Sent' },
      ]);
      mockImapClient.search.mockResolvedValue([1]);
      mockImapClient.fetch.mockImplementation(
        fetchYielding([{ uid: 1, to: 'someone@x.com' }]),
      );

      const result: InboxMessageResponse[] = await service.listMessages(
        'user-1',
        'sent',
        6,
        200,
      );

      expect(mockImapClient.getMailboxLock).toHaveBeenCalledWith('INBOX.Sent');
      expect(result[0].to).toBe('someone@x.com');
    });

    it('falls back to a common folder name when no special-use flag is advertised', async () => {
      mockImapClient.list.mockResolvedValue([
        { path: 'INBOX', specialUse: undefined },
        { path: 'Sent Items', specialUse: undefined },
      ]);
      mockImapClient.search.mockResolvedValue([]);

      await service.listMessages('user-1', 'sent', 6, 200);

      expect(mockImapClient.getMailboxLock).toHaveBeenCalledWith('Sent Items');
    });

    it('throws when no Sent folder can be found at all', async () => {
      mockImapClient.list.mockResolvedValue([
        { path: 'INBOX', specialUse: undefined },
      ]);

      await expect(
        service.listMessages('user-1', 'sent', 6, 200),
      ).rejects.toThrow(BadRequestException);
    });

    it('returns an empty list when the search finds nothing', async () => {
      mockImapClient.search.mockResolvedValue([]);

      const result: InboxMessageResponse[] = await service.listMessages(
        'user-1',
        'inbox',
        6,
        200,
      );

      expect(result).toEqual([]);
      expect(mockImapClient.fetch).not.toHaveBeenCalled();
    });
  });

  describe('listThreads', () => {
    beforeEach(() => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      emailAccountRepository.findByEmployeeId.mockResolvedValue(
        buildAccount({
          encryptedPassword: encryptCredential('mailbox-password', TEST_KEY),
        }),
      );
      mockImapClient.list.mockResolvedValue([
        { path: 'INBOX', specialUse: undefined },
        { path: 'INBOX.Sent', specialUse: '\\Sent' },
      ]);
    });

    it('groups an inbox message and its sent reply into one conversation', async () => {
      mockImapClient.search
        .mockResolvedValueOnce([1]) // inbox
        .mockResolvedValueOnce([2]); // sent
      mockImapClient.fetch
        .mockImplementationOnce(
          fetchYielding([
            {
              uid: 1,
              from: 'client@example.com',
              subject: 'Project update',
              date: new Date('2026-01-01'),
              seen: false,
            },
          ]),
        )
        .mockImplementationOnce(
          fetchYielding([
            {
              uid: 2,
              to: 'client@example.com',
              subject: 'Re: Project update',
              date: new Date('2026-01-02'),
            },
          ]),
        );

      const result = await service.listThreads('user-1', 6, 200);

      expect(result).toHaveLength(1);
      expect(result[0].subject).toBe('Re: Project update');
      expect(result[0].messageCount).toBe(2);
      expect(result[0].hasInboxMessage).toBe(true);
      expect(result[0].hasSentMessage).toBe(true);
      expect(result[0].hasUnread).toBe(true);
      expect(result[0].participants).toContain('client@example.com');
    });

    it('keeps unrelated subjects as separate conversations', async () => {
      mockImapClient.search
        .mockResolvedValueOnce([1])
        .mockResolvedValueOnce([]);
      mockImapClient.fetch.mockImplementationOnce(
        fetchYielding([
          { uid: 1, subject: 'Alpha', date: new Date('2026-01-01') },
        ]),
      );

      const result = await service.listThreads('user-1', 6, 200);

      expect(result).toHaveLength(1);
      expect(result[0].subject).toBe('Alpha');
    });
  });

  describe('getThread', () => {
    beforeEach(() => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      emailAccountRepository.findByEmployeeId.mockResolvedValue(
        buildAccount({
          encryptedPassword: encryptCredential('mailbox-password', TEST_KEY),
        }),
      );
      mockImapClient.list.mockResolvedValue([
        { path: 'INBOX', specialUse: undefined },
        { path: 'INBOX.Sent', specialUse: '\\Sent' },
      ]);
    });

    it('returns every matching message across Inbox and Sent, oldest first', async () => {
      mockImapClient.search
        .mockResolvedValueOnce([1])
        .mockResolvedValueOnce([2]);
      mockImapClient.fetch
        .mockImplementationOnce(
          fetchYielding([
            {
              uid: 1,
              from: 'client@example.com',
              subject: 'Project update',
              date: new Date('2026-01-02'),
            },
          ]),
        )
        .mockImplementationOnce(
          fetchYielding([
            {
              uid: 2,
              to: 'client@example.com',
              subject: 'Re: Project update',
              date: new Date('2026-01-01'),
            },
          ]),
        );
      mockImapClient.download
        .mockResolvedValueOnce(rawMessageDownload('First reply body'))
        .mockResolvedValueOnce(rawMessageDownload('Original body'));

      const threadId = Buffer.from('project update', 'utf8').toString(
        'base64url',
      );
      const result = await service.getThread('user-1', threadId, 6);

      expect(result.messages).toHaveLength(2);
      // Sorted oldest first, regardless of which mailbox fetched last.
      expect(result.messages[0].mailbox).toBe('sent');
      expect(result.messages[0].uid).toBe(2);
      expect(result.messages[1].mailbox).toBe('inbox');
      expect(result.messages[1].uid).toBe(1);
      expect(result.messages[0].text).toContain('Original body');
    });

    it('throws NotFoundException when no message matches the thread id', async () => {
      mockImapClient.search.mockResolvedValueOnce([]).mockResolvedValueOnce([]);

      const threadId = Buffer.from('nothing here', 'utf8').toString(
        'base64url',
      );
      await expect(service.getThread('user-1', threadId, 6)).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
