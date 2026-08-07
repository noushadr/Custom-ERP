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
}
