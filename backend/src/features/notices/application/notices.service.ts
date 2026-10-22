import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { definedFieldsOnly } from '../../../core/utils/defined-fields-only.util';
import { resolveActorName } from '../../../core/utils/resolve-actor-name.util';
import {
  USER_REPOSITORY,
  type UserRepository,
} from '../../authentication/domain/repositories/user-repository.interface';
import {
  EMPLOYEE_REPOSITORY,
  type EmployeeRepository,
} from '../../employee/domain/repositories/employee-repository.interface';
import { Notice } from '../domain/entities/notice.entity';
import {
  NoticeDisplayDuration,
  expiryDateFor,
} from '../domain/enums/notice-display-duration.enum';
import {
  NOTICE_REPOSITORY,
  type NoticeRepository,
} from '../domain/repositories/notice-repository.interface';
import { CreateNoticeDto } from './dto/create-notice.dto';
import { UpdateNoticeDto } from './dto/update-notice.dto';

@Injectable()
export class NoticesService {
  constructor(
    @Inject(NOTICE_REPOSITORY)
    private readonly noticeRepository: NoticeRepository,
    @Inject(EMPLOYEE_REPOSITORY)
    private readonly employeeRepository: EmployeeRepository,
    @Inject(USER_REPOSITORY)
    private readonly userRepository: UserRepository,
  ) {}

  /** What staff see: notices that haven't expired yet. */
  findActive(): Promise<Notice[]> {
    return this.noticeRepository.findActive(new Date());
  }

  /** For whoever manages notices, so an expired one can still be edited,
   * brought back, or deleted. */
  findAllIncludingExpired(): Promise<Notice[]> {
    return this.noticeRepository.findAll();
  }

  async create(dto: CreateNoticeDto, actorUserId: string): Promise<Notice> {
    const authorName = await resolveActorName(
      this.employeeRepository,
      this.userRepository,
      actorUserId,
    );

    const notice = new Notice();
    notice.title = dto.title;
    notice.body = dto.body;
    notice.authorUserId = actorUserId;
    notice.authorName = authorName;
    notice.expiresAt = expiryDateFor(
      dto.displayDuration ?? NoticeDisplayDuration.ALWAYS,
      new Date(),
    );

    return this.noticeRepository.save(notice);
  }

  async update(id: string, dto: UpdateNoticeDto): Promise<Notice> {
    const notice = await this.noticeRepository.findById(id);
    if (!notice) throw new NotFoundException('Notice not found');

    // `displayDuration` isn't a column — it's turned into `expiresAt`, counted
    // from now, so picking a duration on an expired notice brings it back.
    const { displayDuration, ...fields } = dto;
    Object.assign(notice, definedFieldsOnly(fields));
    if (displayDuration !== undefined) {
      notice.expiresAt = expiryDateFor(displayDuration, new Date());
    }
    return this.noticeRepository.save(notice);
  }

  async delete(id: string): Promise<void> {
    const notice = await this.noticeRepository.findById(id);
    if (!notice) throw new NotFoundException('Notice not found');

    await this.noticeRepository.remove(notice);
  }
}
