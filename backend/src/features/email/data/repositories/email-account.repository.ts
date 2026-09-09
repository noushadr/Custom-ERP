import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EmailAccount } from '../../domain/entities/email-account.entity';
import { EmailAccountRepository } from '../../domain/repositories/email-account-repository.interface';

@Injectable()
export class TypeOrmEmailAccountRepository implements EmailAccountRepository {
  constructor(
    @InjectRepository(EmailAccount)
    private readonly repository: Repository<EmailAccount>,
  ) {}

  findByEmployeeId(employeeId: string): Promise<EmailAccount | null> {
    return this.repository.findOne({ where: { employeeId } });
  }

  save(account: EmailAccount): Promise<EmailAccount> {
    return this.repository.save(account);
  }

  async remove(account: EmailAccount): Promise<void> {
    await this.repository.remove(account);
  }
}
