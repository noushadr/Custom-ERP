import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { LeaveRequest } from '../../domain/entities/leave-request.entity';
import { LeaveRequestStatus } from '../../domain/enums/leave-request-status.enum';
import { LeaveRequestRepository } from '../../domain/repositories/leave-request-repository.interface';

@Injectable()
export class TypeOrmLeaveRequestRepository implements LeaveRequestRepository {
  constructor(
    @InjectRepository(LeaveRequest)
    private readonly repository: Repository<LeaveRequest>,
  ) {}

  findById(id: string): Promise<LeaveRequest | null> {
    return this.repository.findOne({
      where: { id },
      relations: { employee: true },
    });
  }

  findByEmployeeId(employeeId: string): Promise<LeaveRequest[]> {
    return this.repository.find({
      where: { employeeId },
      relations: { employee: true },
      order: { createdAt: 'DESC' },
    });
  }

  findByStatus(status: LeaveRequestStatus): Promise<LeaveRequest[]> {
    return this.repository.find({
      where: { status },
      relations: { employee: true },
      order: { createdAt: 'ASC' },
    });
  }

  findByStatuses(statuses: LeaveRequestStatus[]): Promise<LeaveRequest[]> {
    return this.repository.find({
      where: { status: In(statuses) },
      relations: { employee: true },
      order: { startDate: 'ASC' },
    });
  }

  save(request: LeaveRequest): Promise<LeaveRequest> {
    return this.repository.save(request);
  }
}
