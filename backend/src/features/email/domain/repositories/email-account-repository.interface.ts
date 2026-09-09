import { EmailAccount } from '../entities/email-account.entity';

export const EMAIL_ACCOUNT_REPOSITORY = Symbol('EMAIL_ACCOUNT_REPOSITORY');

export interface EmailAccountRepository {
  findByEmployeeId(employeeId: string): Promise<EmailAccount | null>;
  save(account: EmailAccount): Promise<EmailAccount>;
  remove(account: EmailAccount): Promise<void>;
}
