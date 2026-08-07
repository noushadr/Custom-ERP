import { Notice } from '../entities/notice.entity';

export const NOTICE_REPOSITORY = Symbol('NOTICE_REPOSITORY');

export interface NoticeRepository {
  findAll(): Promise<Notice[]>;
  save(notice: Notice): Promise<Notice>;
}
