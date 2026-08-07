import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EmployeeAuditLog } from '../../domain/entities/employee-audit-log.entity';
import { AuditLogRepository } from '../../domain/repositories/audit-log-repository.interface';

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

  findAll(limit: number): Promise<EmployeeAuditLog[]> {
    return this.repository.find({
      relations: { employee: true },
      order: { createdAt: 'DESC' },
      take: limit,
    });
  }

  saveMany(entries: EmployeeAuditLog[]): Promise<EmployeeAuditLog[]> {
    return this.repository.save(entries);
  }
}
