import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthenticationModule } from '../authentication/authentication.module';
import { EmployeeModule } from '../employee/employee.module';
import { EmailService } from './application/email.service';
import { TypeOrmEmailAccountRepository } from './data/repositories/email-account.repository';
import { EmailAccount } from './domain/entities/email-account.entity';
import { EMAIL_ACCOUNT_REPOSITORY } from './domain/repositories/email-account-repository.interface';
import { EmailController } from './presentation/email.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([EmailAccount]),
    AuthenticationModule,
    EmployeeModule,
  ],
  controllers: [EmailController],
  providers: [
    EmailService,
    { provide: EMAIL_ACCOUNT_REPOSITORY, useClass: TypeOrmEmailAccountRepository },
  ],
})
export class EmailModule {}
