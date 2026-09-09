import { Column, Entity, JoinColumn, OneToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Employee } from '../../../employee/domain/entities/employee.entity';

/** One employee's real, working cPanel mailbox — created manually by
 * Admin/HR in cPanel first, then its credentials are entered here so the
 * employee (and Admin/HR, who are also employees) can send/receive through
 * it from inside the ERP. `encryptedPassword` is AES-256-GCM ciphertext
 * (see `credential-crypto.util.ts`) — never stored or returned in plain
 * text past the request that set it. */
@Entity('email_accounts')
export class EmailAccount extends BaseEntity {
  @Column({ unique: true })
  employeeId: string;

  @OneToOne(() => Employee, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'employeeId' })
  employee: Employee;

  @Column()
  emailAddress: string;

  @Column()
  encryptedPassword: string;

  @Column()
  smtpHost: string;

  @Column({ type: 'int', default: 587 })
  smtpPort: number;

  @Column()
  imapHost: string;

  @Column({ type: 'int', default: 993 })
  imapPort: number;

  /** Whether SMTP should connect with implicit TLS (port 465) vs. STARTTLS
   * on a plaintext connection (587) — cPanel/Verpex support both. */
  @Column({ default: true })
  smtpSecure: boolean;
}
