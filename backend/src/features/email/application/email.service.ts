import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ImapFlow } from 'imapflow';
import { simpleParser } from 'mailparser';
import * as nodemailer from 'nodemailer';
// eslint-disable-next-line @typescript-eslint/no-require-imports
const MailComposer = require('nodemailer/lib/mail-composer') as new (
  mail: Record<string, unknown>,
) => {
  compile: () => {
    build: (cb: (err: Error | null, message: Buffer) => void) => void;
  };
};
import {
  decryptCredential,
  encryptCredential,
} from '../../../core/crypto/credential-crypto.util';
import {
  EMPLOYEE_REPOSITORY,
  type EmployeeRepository,
} from '../../employee/domain/repositories/employee-repository.interface';
import { SendEmailDto } from './dto/send-email.dto';
import { SetupEmailAccountDto } from './dto/setup-email-account.dto';
import { EmailAccount } from '../domain/entities/email-account.entity';
import {
  EMAIL_ACCOUNT_REPOSITORY,
  type EmailAccountRepository,
} from '../domain/repositories/email-account-repository.interface';
import { EmailAccountResponse } from './email-account-response.interface';
import { toEmailAccountResponse } from './email-account.mapper';
import { InboxMessageResponse } from './inbox-message-response.interface';
import {
  ThreadDetailResponse,
  ThreadMessageResponse,
  ThreadSummaryResponse,
} from './email-thread-response.interface';

export type MailboxKind = 'inbox' | 'sent';

@Injectable()
export class EmailService {
  constructor(
    @Inject(EMAIL_ACCOUNT_REPOSITORY)
    private readonly emailAccountRepository: EmailAccountRepository,
    @Inject(EMPLOYEE_REPOSITORY)
    private readonly employeeRepository: EmployeeRepository,
    private readonly config: ConfigService,
  ) {}

  /** This viewer's own mailbox config (no password) — `null` means not set
   * up yet, which the frontend renders as a setup form. */
  async getMyAccount(
    actorUserId: string,
  ): Promise<EmailAccountResponse | null> {
    const employee = await this.employeeRepository.findByUserId(actorUserId);
    if (!employee) return null;
    const account = await this.emailAccountRepository.findByEmployeeId(
      employee.id,
    );
    return account ? toEmailAccountResponse(account) : null;
  }

  async getAccountForEmployee(
    employeeId: string,
  ): Promise<EmailAccountResponse | null> {
    const account =
      await this.emailAccountRepository.findByEmployeeId(employeeId);
    return account ? toEmailAccountResponse(account) : null;
  }

  /** The employee enters their own real cPanel mailbox's credentials —
   * identity-scoped, no `email.manage` needed since it's their own record. */
  async setupMyAccount(
    actorUserId: string,
    dto: SetupEmailAccountDto,
  ): Promise<EmailAccountResponse> {
    const employee = await this.employeeRepository.findByUserId(actorUserId);
    if (!employee) throw new NotFoundException('Employee profile not found');
    return this.setup(employee.id, dto);
  }

  /** Admin/HR entering a mailbox's credentials on behalf of an employee who
   * can't or hasn't done it themselves — gated by `email.manage`. */
  async setupForEmployee(
    employeeId: string,
    dto: SetupEmailAccountDto,
  ): Promise<EmailAccountResponse> {
    const employee = await this.employeeRepository.findById(employeeId);
    if (!employee) throw new NotFoundException('Employee not found');
    return this.setup(employeeId, dto);
  }

  async removeMyAccount(actorUserId: string): Promise<void> {
    const employee = await this.employeeRepository.findByUserId(actorUserId);
    if (!employee) return;
    await this.remove(employee.id);
  }

  async removeForEmployee(employeeId: string): Promise<void> {
    await this.remove(employeeId);
  }

  /** Sends as the viewer's own mailbox, using their own stored SMTP config
   * and decrypted password. */
  async sendMail(actorUserId: string, dto: SendEmailDto): Promise<void> {
    const account = await this.loadMyAccountOrThrow(actorUserId);
    const password = this.decryptPassword(account);

    const transporter = nodemailer.createTransport({
      host: account.smtpHost,
      port: account.smtpPort,
      secure: account.smtpSecure,
      auth: { user: account.emailAddress, pass: password },
    });

    // Built once as raw MIME so the exact bytes sent over SMTP are also
    // what gets APPENDed to the Sent folder below — sending the same
    // fields twice (once via nodemailer's own composer, once implicitly
    // by ImapFlow) risks a different Message-Id/boundary between the two.
    const raw = await new Promise<Buffer>((resolve, reject) => {
      new MailComposer({
        from: account.emailAddress,
        to: dto.to,
        subject: dto.subject,
        text: dto.body,
      })
        .compile()
        .build((err, message) => (err ? reject(err) : resolve(message)));
    });

    try {
      await transporter.sendMail({ raw });
    } catch {
      throw new BadRequestException(
        'Could not send the email — check the mailbox settings and try again.',
      );
    }

    // Plain SMTP relay never copies a sent message into the mailbox's own
    // Sent folder — that's normally done by the mail *client* (Outlook,
    // Thunderbird, webmail) via an explicit IMAP APPEND after sending. Since
    // this app sends over raw SMTP, do that ourselves so messages sent
    // through the ERP actually show up in the Sent tab. Best-effort: a
    // failure here shouldn't fail the send, which already succeeded.
    const client = this.openImapClient(account, password);
    try {
      await client.connect();
      const path = await this.resolveMailboxPath(client, 'sent');
      await client.append(path, raw, ['\\Seen']);
    } catch {
      // Best-effort — the email was already sent successfully.
    } finally {
      await client.logout().catch(() => undefined);
    }
  }

  /** Fetches messages from the viewer's own Inbox or Sent folder, newest
   * first — headers only (no body), fetched live from the mail server on
   * every call rather than synced/cached locally. Scoped to the last
   * [monthsBack] months (via IMAP SEARCH SINCE, not a blind sequence-number
   * range) and capped at [limit] messages so a very active mailbox doesn't
   * pull an unbounded number of headers. */
  async listMessages(
    actorUserId: string,
    mailbox: MailboxKind,
    monthsBack: number,
    limit: number,
  ): Promise<InboxMessageResponse[]> {
    const account = await this.loadMyAccountOrThrow(actorUserId);
    const password = this.decryptPassword(account);
    const client = this.openImapClient(account, password);

    try {
      await client.connect();
      const messages = await this.fetchMailboxEnvelopes(
        client,
        mailbox,
        monthsBack,
        limit,
      );
      return messages.sort(
        (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime(),
      );
    } catch (error) {
      if (error instanceof BadRequestException) throw error;
      throw new BadRequestException(
        'Could not connect to the mailbox — check the mailbox settings and try again.',
      );
    } finally {
      await client.logout().catch(() => undefined);
    }
  }

  /** Groups Inbox + Sent into Gmail-style conversations by subject (no
   * References/In-Reply-To chaining — this "lighter version" doesn't sync
   * or store headers, so subject is the only cheap, always-available
   * grouping key available from a single live IMAP round trip). A
   * conversation counts as "in the Inbox" or "in Sent" if any of its
   * messages live in that folder, mirroring how Gmail's own folder views
   * work off one underlying thread. */
  async listThreads(
    actorUserId: string,
    monthsBack: number,
    limit: number,
  ): Promise<ThreadSummaryResponse[]> {
    const account = await this.loadMyAccountOrThrow(actorUserId);
    const password = this.decryptPassword(account);
    const client = this.openImapClient(account, password);

    try {
      await client.connect();
      const inbox = await this.fetchMailboxEnvelopes(
        client,
        'inbox',
        monthsBack,
        limit,
      );
      const sent = await this.fetchMailboxEnvelopes(
        client,
        'sent',
        monthsBack,
        limit,
      );

      interface ThreadAccumulator {
        subject: string;
        participants: Set<string>;
        lastDate: string;
        count: number;
        hasUnread: boolean;
        hasInboxMessage: boolean;
        hasSentMessage: boolean;
      }
      const threads = new Map<string, ThreadAccumulator>();

      const addMessage = (
        message: InboxMessageResponse,
        mailbox: MailboxKind,
      ) => {
        const key = this.normalizeSubject(message.subject);
        const participant =
          (mailbox === 'inbox' ? message.from : message.to) ?? undefined;
        const existing = threads.get(key);
        if (existing) {
          existing.count += 1;
          if (participant) existing.participants.add(participant);
          if (new Date(message.date) > new Date(existing.lastDate)) {
            existing.lastDate = message.date;
            existing.subject = message.subject;
          }
          if (mailbox === 'inbox') {
            existing.hasInboxMessage = true;
            if (message.isUnread) existing.hasUnread = true;
          } else {
            existing.hasSentMessage = true;
          }
        } else {
          threads.set(key, {
            subject: message.subject,
            participants: new Set(participant ? [participant] : []),
            lastDate: message.date,
            count: 1,
            hasUnread: mailbox === 'inbox' && message.isUnread,
            hasInboxMessage: mailbox === 'inbox',
            hasSentMessage: mailbox === 'sent',
          });
        }
      };

      for (const message of inbox) addMessage(message, 'inbox');
      for (const message of sent) addMessage(message, 'sent');

      const summaries: ThreadSummaryResponse[] = Array.from(
        threads.entries(),
      ).map(([key, thread]) => ({
        threadId: this.encodeThreadId(key),
        subject: thread.subject,
        participants: Array.from(thread.participants).slice(0, 5),
        lastDate: thread.lastDate,
        messageCount: thread.count,
        hasUnread: thread.hasUnread,
        hasInboxMessage: thread.hasInboxMessage,
        hasSentMessage: thread.hasSentMessage,
      }));

      return summaries
        .sort(
          (a, b) =>
            new Date(b.lastDate).getTime() - new Date(a.lastDate).getTime(),
        )
        .slice(0, limit);
    } catch (error) {
      if (error instanceof BadRequestException) throw error;
      throw new BadRequestException(
        'Could not connect to the mailbox — check the mailbox settings and try again.',
      );
    } finally {
      await client.logout().catch(() => undefined);
    }
  }

  /** Fetches every message in one conversation (Inbox + Sent, matched by
   * subject — see `listThreads`), oldest first, with full bodies. */
  async getThread(
    actorUserId: string,
    threadId: string,
    monthsBack: number,
  ): Promise<ThreadDetailResponse> {
    const targetSubjectKey = this.decodeThreadId(threadId);
    const account = await this.loadMyAccountOrThrow(actorUserId);
    const password = this.decryptPassword(account);
    const client = this.openImapClient(account, password);

    try {
      await client.connect();
      const inbox = await this.fetchMailboxEnvelopes(
        client,
        'inbox',
        monthsBack,
        500,
      );
      const sent = await this.fetchMailboxEnvelopes(
        client,
        'sent',
        monthsBack,
        500,
      );

      const matching: {
        mailbox: MailboxKind;
        envelope: InboxMessageResponse;
      }[] = [
        ...inbox
          .filter((m) => this.normalizeSubject(m.subject) === targetSubjectKey)
          .map((envelope) => ({ mailbox: 'inbox' as const, envelope })),
        ...sent
          .filter((m) => this.normalizeSubject(m.subject) === targetSubjectKey)
          .map((envelope) => ({ mailbox: 'sent' as const, envelope })),
      ];

      if (matching.length === 0) {
        throw new NotFoundException('Conversation not found');
      }

      const messages: ThreadMessageResponse[] = [];
      for (const mailbox of ['inbox', 'sent'] as const) {
        const forMailbox = matching.filter((m) => m.mailbox === mailbox);
        if (forMailbox.length === 0) continue;

        const path = await this.resolveMailboxPath(client, mailbox);
        const lock = await client.getMailboxLock(path);
        try {
          for (const { envelope } of forMailbox) {
            const raw = await client.download(String(envelope.uid), undefined, {
              uid: true,
            });
            if (!raw) continue;
            const chunks: Buffer[] = [];
            for await (const chunk of raw.content) chunks.push(chunk as Buffer);
            const parsed = await simpleParser(Buffer.concat(chunks));
            messages.push({
              mailbox,
              uid: envelope.uid,
              from: envelope.from,
              fromName: envelope.fromName,
              to: envelope.to,
              toName: envelope.toName,
              date: envelope.date,
              text: parsed.text ?? '',
              isUnread: envelope.isUnread,
            });
          }
        } finally {
          lock.release();
        }
      }

      messages.sort(
        (a, b) => new Date(a.date).getTime() - new Date(b.date).getTime(),
      );

      const latest = matching.reduce((a, b) =>
        new Date(a.envelope.date) > new Date(b.envelope.date) ? a : b,
      );

      return { threadId, subject: latest.envelope.subject, messages };
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
      if (error instanceof BadRequestException) throw error;
      throw new BadRequestException(
        'Could not load the conversation — check the mailbox settings and try again.',
      );
    } finally {
      await client.logout().catch(() => undefined);
    }
  }

  /** Fetches one message's full body by IMAP UID, from the viewer's own
   * Inbox or Sent folder. */
  async getMessage(
    actorUserId: string,
    mailbox: MailboxKind,
    uid: number,
  ): Promise<{
    subject: string;
    from: string;
    to: string | null;
    date: string;
    text: string;
  }> {
    const account = await this.loadMyAccountOrThrow(actorUserId);
    const password = this.decryptPassword(account);
    const client = this.openImapClient(account, password);

    try {
      await client.connect();
      const path = await this.resolveMailboxPath(client, mailbox);
      const lock = await client.getMailboxLock(path);
      try {
        const raw = await client.download(String(uid), undefined, {
          uid: true,
        });
        if (!raw) throw new NotFoundException('Message not found');
        const chunks: Buffer[] = [];
        for await (const chunk of raw.content) chunks.push(chunk as Buffer);
        const parsed = await simpleParser(Buffer.concat(chunks));
        return {
          subject: parsed.subject ?? '(no subject)',
          from: parsed.from?.text ?? 'Unknown sender',
          to: Array.isArray(parsed.to)
            ? (parsed.to[0]?.text ?? null)
            : (parsed.to?.text ?? null),
          date: (parsed.date ?? new Date()).toISOString(),
          text: parsed.text ?? '',
        };
      } finally {
        lock.release();
      }
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
      if (error instanceof BadRequestException) throw error;
      throw new BadRequestException(
        'Could not load the message — check the mailbox settings and try again.',
      );
    } finally {
      await client.logout().catch(() => undefined);
    }
  }

  /** Headers-only fetch (no body) for one mailbox, scoped to the last
   * [monthsBack] months and capped at [limit] messages — shared by
   * `listMessages`, `listThreads`, and `getThread` so the SINCE-search +
   * fetch logic lives in exactly one place. Returned in whatever order
   * `search` gives back (ascending by UID); callers sort as needed. */
  private async fetchMailboxEnvelopes(
    client: ImapFlow,
    mailbox: MailboxKind,
    monthsBack: number,
    limit: number,
  ): Promise<InboxMessageResponse[]> {
    const path = await this.resolveMailboxPath(client, mailbox);
    const lock = await client.getMailboxLock(path);
    try {
      const since = new Date();
      since.setMonth(since.getMonth() - monthsBack);

      const uids = await client.search({ since }, { uid: true });
      if (!uids || uids.length === 0) return [];

      // `search` returns UIDs in ascending (oldest-first) order — the most
      // recent [limit] are the tail of that list.
      const scoped = uids.length > limit ? uids.slice(-limit) : uids;

      const messages: InboxMessageResponse[] = [];
      for await (const message of client.fetch(
        scoped,
        { envelope: true, flags: true },
        { uid: true },
      )) {
        messages.push({
          uid: message.uid,
          from: message.envelope?.from?.[0]?.address ?? 'Unknown sender',
          fromName: message.envelope?.from?.[0]?.name ?? null,
          to: message.envelope?.to?.[0]?.address ?? null,
          toName: message.envelope?.to?.[0]?.name ?? null,
          subject: message.envelope?.subject ?? '(no subject)',
          date: new Date(message.envelope?.date ?? new Date()).toISOString(),
          isUnread: !message.flags?.has('\\Seen'),
        });
      }
      return messages;
    } finally {
      lock.release();
    }
  }

  /** Strips a leading Re:/Fwd:/Fw: (any casing, possibly repeated across
   * several rounds of replying/forwarding) and normalizes whitespace/case,
   * so "Project update", "Re: Project update", and "RE: Re: Project
   * update" all group into the same conversation. */
  private normalizeSubject(subject: string): string {
    let result = subject.trim();
    const prefixPattern = /^(re|fwd?|fw)\s*:\s*/i;
    while (prefixPattern.test(result)) {
      result = result.replace(prefixPattern, '').trim();
    }
    return result.toLowerCase().replace(/\s+/g, ' ');
  }

  private encodeThreadId(normalizedSubject: string): string {
    return Buffer.from(normalizedSubject, 'utf8').toString('base64url');
  }

  private decodeThreadId(threadId: string): string {
    return Buffer.from(threadId, 'base64url').toString('utf8');
  }

  /** `INBOX` needs no lookup. The Sent folder's real name varies by mail
   * server (cPanel/Dovecot commonly uses `INBOX.Sent`, others just `Sent`
   * or `Sent Items`) — ImapFlow already resolves special-use folders from
   * the server's own SPECIAL-USE hint or, failing that, common localized
   * names, so trust `list()`'s `specialUse` flag first and fall back to a
   * fixed name list only if the server advertises neither. */
  private async resolveMailboxPath(
    client: ImapFlow,
    mailbox: MailboxKind,
  ): Promise<string> {
    if (mailbox === 'inbox') return 'INBOX';

    const folders = await client.list();
    const bySpecialUse = folders.find((f) => f.specialUse === '\\Sent');
    if (bySpecialUse) return bySpecialUse.path;

    const commonNames = [
      'Sent',
      'Sent Items',
      'Sent Messages',
      'Sent Mail',
      'INBOX.Sent',
      'INBOX/Sent',
      'INBOX.Sent Items',
      'INBOX/Sent Items',
      'INBOX.Sent Messages',
      'INBOX.Sent Mail',
    ];
    const byName = folders.find((f) =>
      commonNames.some((name) => name.toLowerCase() === f.path.toLowerCase()),
    );
    if (byName) return byName.path;

    // Fall back to a loose substring match ("sent") — catches server-specific
    // naming/prefixes (e.g. a non-default IMAP namespace) none of the exact
    // names above account for.
    const byContains = folders.find((f) =>
      f.path.toLowerCase().includes('sent'),
    );
    if (byContains) return byContains.path;

    // List the real folder names in the error so a failure here is
    // diagnosable from the frontend's error message alone, instead of
    // collapsing into the generic "could not connect" message below.
    const available = folders.map((f) => f.path).join(', ') || '(none)';
    throw new BadRequestException(
      `Could not find a Sent folder on this mailbox. Folders found: ${available}`,
    );
  }

  private async setup(
    employeeId: string,
    dto: SetupEmailAccountDto,
  ): Promise<EmailAccountResponse> {
    const key = this.credentialKey();
    const account =
      (await this.emailAccountRepository.findByEmployeeId(employeeId)) ??
      new EmailAccount();

    account.employeeId = employeeId;
    account.emailAddress = dto.emailAddress;
    account.encryptedPassword = encryptCredential(dto.password, key);
    account.smtpHost = dto.smtpHost;
    account.smtpPort = dto.smtpPort ?? 587;
    account.imapHost = dto.imapHost;
    account.imapPort = dto.imapPort ?? 993;
    account.smtpSecure = dto.smtpSecure ?? true;

    const saved = await this.emailAccountRepository.save(account);
    return toEmailAccountResponse(saved);
  }

  private async remove(employeeId: string): Promise<void> {
    const account =
      await this.emailAccountRepository.findByEmployeeId(employeeId);
    if (!account) return;
    await this.emailAccountRepository.remove(account);
  }

  private async loadMyAccountOrThrow(
    actorUserId: string,
  ): Promise<EmailAccount> {
    const employee = await this.employeeRepository.findByUserId(actorUserId);
    if (!employee) throw new NotFoundException('Employee profile not found');
    const account = await this.emailAccountRepository.findByEmployeeId(
      employee.id,
    );
    if (!account) {
      throw new BadRequestException(
        'No mailbox is set up for you yet — add your mailbox details first.',
      );
    }
    return account;
  }

  private decryptPassword(account: EmailAccount): string {
    return decryptCredential(account.encryptedPassword, this.credentialKey());
  }

  private credentialKey(): string {
    const key = this.config.get<string>('emailCredentialKey');
    if (!key) {
      throw new BadRequestException('Email encryption key is not configured');
    }
    return key;
  }

  private openImapClient(account: EmailAccount, password: string): ImapFlow {
    return new ImapFlow({
      host: account.imapHost,
      port: account.imapPort,
      secure: account.imapPort === 993,
      auth: { user: account.emailAddress, pass: password },
      logger: false,
    });
  }
}
