import { Notice } from '../entities/notice.entity';

export const NOTICE_REPOSITORY = Symbol('NOTICE_REPOSITORY');

export interface NoticeRepository {
  /** Every notice, including expired ones — newest first. */
  findAll(): Promise<Notice[]>;
  /** Only notices that haven't expired as of [now] (never-expiring ones
   * included) — newest first. */
  findActive(now: Date): Promise<Notice[]>;
  findById(id: string): Promise<Notice | null>;
  save(notice: Notice): Promise<Notice>;
  remove(notice: Notice): Promise<void>;
}
