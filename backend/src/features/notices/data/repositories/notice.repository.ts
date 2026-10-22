import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, MoreThan, Repository } from 'typeorm';
import { Notice } from '../../domain/entities/notice.entity';
import { NoticeRepository } from '../../domain/repositories/notice-repository.interface';

@Injectable()
export class TypeOrmNoticeRepository implements NoticeRepository {
  constructor(
    @InjectRepository(Notice)
    private readonly repository: Repository<Notice>,
  ) {}

  findAll(): Promise<Notice[]> {
    return this.repository.find({ order: { createdAt: 'DESC' } });
  }

  findActive(now: Date): Promise<Notice[]> {
    return this.repository.find({
      where: [{ expiresAt: IsNull() }, { expiresAt: MoreThan(now) }],
      order: { createdAt: 'DESC' },
    });
  }

  findById(id: string): Promise<Notice | null> {
    return this.repository.findOneBy({ id });
  }

  save(notice: Notice): Promise<Notice> {
    return this.repository.save(notice);
  }

  async remove(notice: Notice): Promise<void> {
    await this.repository.remove(notice);
  }
}
