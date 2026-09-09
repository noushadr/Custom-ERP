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
  async getMyAccount(actorUserId: string): Promise<EmailAccountResponse | null> {
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
    const account = await this.emailAccountRepository.findByEmployeeId(
      employeeId,
    );
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

    try {
      await transporter.sendMail({
        from: account.emailAddress,
        to: dto.to,
        subject: dto.subject,
        text: dto.body,
      });
    } catch {
      throw new BadRequestException(
        'Could not send the email — check the mailbox settings and try again.',
      );
    }
  }

  /** Fetches the most recent messages from the viewer's own INBOX, newest
   * first — headers only (no body), fetched live from the mail server on
   * every call rather than synced/cached locally. */
  async listInbox(
    actorUserId: string,
    limit: number,
  ): Promise<InboxMessageResponse[]> {
    const account = await this.loadMyAccountOrThrow(actorUserId);
    const password = this.decryptPassword(account);
    const client = this.openImapClient(account, password);

    try {
      await client.connect();
      const lock = await client.getMailboxLock('INBOX');
      try {
        const total = client.mailbox && 'exists' in client.mailbox
          ? client.mailbox.exists
          : 0;
        if (total === 0) return [];

        const from = Math.max(1, total - limit + 1);
        const messages: InboxMessageResponse[] = [];
        for await (const message of client.fetch(`${from}:${total}`, {
          envelope: true,
          flags: true,
        })) {
          messages.push({
            uid: message.uid,
            from: message.envelope?.from?.[0]?.address ?? 'Unknown sender',
            fromName: message.envelope?.from?.[0]?.name ?? null,
            subject: message.envelope?.subject ?? '(no subject)',
            date: new Date(message.envelope?.date ?? new Date()).toISOString(),
            isUnread: !message.flags?.has('\\Seen'),
          });
        }
        return messages.reverse();
      } finally {
        lock.release();
      }
    } catch {
      throw new BadRequestException(
        'Could not connect to the mailbox — check the mailbox settings and try again.',
      );
    } finally {
      await client.logout().catch(() => undefined);
    }
  }

  /** Fetches one message's full body by IMAP UID, from the viewer's own
   * INBOX only. */
  async getMessage(
    actorUserId: string,
    uid: number,
  ): Promise<{ subject: string; from: string; date: string; text: string }> {
    const account = await this.loadMyAccountOrThrow(actorUserId);
    const password = this.decryptPassword(account);
    const client = this.openImapClient(account, password);

    try {
      await client.connect();
      const lock = await client.getMailboxLock('INBOX');
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
          date: (parsed.date ?? new Date()).toISOString(),
          text: parsed.text ?? '',
        };
      } finally {
        lock.release();
      }
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
      throw new BadRequestException(
        'Could not load the message — check the mailbox settings and try again.',
      );
    } finally {
      await client.logout().catch(() => undefined);
    }
  }

  private async setup(
    employeeId: string,
    dto: SetupEmailAccountDto,
  ): Promise<EmailAccountResponse> {
    const key = this.credentialKey();
    let account =
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
    const account = await this.emailAccountRepository.findByEmployeeId(
      employeeId,
    );
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
