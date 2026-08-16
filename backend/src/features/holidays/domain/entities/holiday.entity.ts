import { Column, Entity } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';

@Entity('holidays')
export class Holiday extends BaseEntity {
  @Column()
  name: string;

  @Column({ type: 'date' })
  date: string;
}
