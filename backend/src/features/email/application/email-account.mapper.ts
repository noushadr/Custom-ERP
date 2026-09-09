import { EmailAccount } from '../domain/entities/email-account.entity';
import { EmailAccountResponse } from './email-account-response.interface';

export function toEmailAccountResponse(
  account: EmailAccount,
): EmailAccountResponse {
  return {
    id: account.id,
    employeeId: account.employeeId,
    emailAddress: account.emailAddress,
    smtpHost: account.smtpHost,
    smtpPort: account.smtpPort,
    imapHost: account.imapHost,
    imapPort: account.imapPort,
    smtpSecure: account.smtpSecure,
  };
}
