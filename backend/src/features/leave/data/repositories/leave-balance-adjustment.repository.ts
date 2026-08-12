import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { LeaveBalanceAdjustment } from '../../domain/entities/leave-balance-adjustment.entity';
import { LeaveBalanceAdjustmentRepository } from '../../domain/repositories/leave-balance-adjustment-repository.interface';

@Injectable()
export class TypeOrmLeaveBalanceAdjustmentRepository
  implements LeaveBalanceAdjustmentRepository
{
  constructor(
    @InjectRepository(LeaveBalanceAdjustment)
    private readonly repository: Repository<LeaveBalanceAdjustment>,
  ) {}

  findByEmployeeId(employeeId: string): Promise<LeaveBalanceAdjustment[]> {
    return this.repository.find({
      where: { employeeId },
      order: { createdAt: 'DESC' },
    });
  }

  save(
    adjustment: LeaveBalanceAdjustment,
  ): Promise<LeaveBalanceAdjustment> {
    return this.repository.save(adjustment);
  }
}
