import { Column, Entity } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';

/** One employee's real, working cPanel mailbox — created manually by
 * Admin/HR in cPanel first, then its credentials are entered here so the
 * employee (and Admin/HR, who are also employees) can send/receive through
 * it from inside the ERP. `encryptedPassword` is AES-256-GCM ciphertext
 * (see `credential-crypto.util.ts`) — never stored or returned in plain
 * text past the request that set it. */
@Entity('email_accounts')
export class EmailAccount extends BaseEntity {
  // Explicit `type: 'uuid'` needed now that this isn't also a relation's
  // join column — a bare `@Column({ unique: true })` infers `varchar` from
  // the TS `string` type, which would otherwise make `synchronize: true`
  // attempt a live column-type ALTER against real rows on next boot (it
  // did, and failed — see CLAUDE.md's cleanup entry). `Employee.id` is a
  // `uuid` primary key, and this column always held real UUIDs; this keeps
  // the actual schema unchanged.
  @Column({ type: 'uuid', unique: true })
  employeeId: string;

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
