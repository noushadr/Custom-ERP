import { Column, Entity } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';

@Entity('notices')
export class Notice extends BaseEntity {
  @Column()
  title: string;

  @Column({ type: 'text' })
  body: string;

  @Column()
  authorUserId: string;

  /** Snapshot of the author's display name at post time, so the notice
   * stays readable even if that person is later renamed or removed. */
  @Column()
  authorName: string;

  /** When the notice stops showing to staff; null means it never expires.
   * Set by the server from a preset (see NoticeDisplayDuration), not by the
   * client. Nullable, so every notice posted before this existed stays
   * visible exactly as before. */
  @Column({ type: 'timestamptz', nullable: true })
  expiresAt: Date | null;
}
