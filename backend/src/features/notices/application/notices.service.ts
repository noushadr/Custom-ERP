import { Inject, Injectable } from '@nestjs/common';
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
  NOTICE_REPOSITORY,
  type NoticeRepository,
} from '../domain/repositories/notice-repository.interface';
import { CreateNoticeDto } from './dto/create-notice.dto';

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

  findAll(): Promise<Notice[]> {
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

    return this.noticeRepository.save(notice);
  }
}
