import { Notice } from '../entities/notice.entity';

export const NOTICE_REPOSITORY = Symbol('NOTICE_REPOSITORY');

export interface NoticeRepository {
  findAll(): Promise<Notice[]>;
  findById(id: string): Promise<Notice | null>;
  save(notice: Notice): Promise<Notice>;
  remove(notice: Notice): Promise<void>;
}
