import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EmployeeAuditLog } from '../../domain/entities/employee-audit-log.entity';
import {
  AuditLogRepository,
  AuditLogSearchParams,
  AuditLogSearchResult,
} from '../../domain/repositories/audit-log-repository.interface';

@Injectable()
export class TypeOrmAuditLogRepository implements AuditLogRepository {
  constructor(
    @InjectRepository(EmployeeAuditLog)
    private readonly repository: Repository<EmployeeAuditLog>,
  ) {}

  findByEmployeeId(employeeId: string): Promise<EmployeeAuditLog[]> {
    return this.repository.find({
      where: { employeeId },
      order: { createdAt: 'DESC' },
    });
  }

  async findAllPaginated({
    page,
    limit,
    search,
  }: AuditLogSearchParams): Promise<AuditLogSearchResult> {
    const query = this.repository
      .createQueryBuilder('log')
      .leftJoinAndSelect('log.employee', 'employee')
      .orderBy('log.createdAt', 'DESC')
      .skip((page - 1) * limit)
      .take(limit);

    if (search) {
      query.andWhere(
        `(employee."firstName" ILIKE :search
          OR employee."lastName" ILIKE :search
          OR log."fieldLabel" ILIKE :search
          OR log."oldValue" ILIKE :search
          OR log."newValue" ILIKE :search
          OR log."actorName" ILIKE :search)`,
        { search: `%${search}%` },
      );
    }

    const [items, total] = await query.getManyAndCount();
    return { items, total };
  }

  saveMany(entries: EmployeeAuditLog[]): Promise<EmployeeAuditLog[]> {
    return this.repository.save(entries);
  }
}
