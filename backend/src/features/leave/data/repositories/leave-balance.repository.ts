import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { LeaveBalance } from '../../domain/entities/leave-balance.entity';
import { LeaveBalanceRepository } from '../../domain/repositories/leave-balance-repository.interface';

@Injectable()
export class TypeOrmLeaveBalanceRepository implements LeaveBalanceRepository {
  constructor(
    @InjectRepository(LeaveBalance)
    private readonly repository: Repository<LeaveBalance>,
  ) {}

  findOne(
    employeeId: string,
    leaveTypeId: string,
    year: number,
  ): Promise<LeaveBalance | null> {
    return this.repository.findOne({ where: { employeeId, leaveTypeId, year } });
  }

  findByEmployeeId(employeeId: string): Promise<LeaveBalance[]> {
    return this.repository.find({
      where: { employeeId },
      order: { year: 'DESC' },
    });
  }

  findByYear(year: number): Promise<LeaveBalance[]> {
    return this.repository.find({ where: { year } });
  }

  save(balance: LeaveBalance): Promise<LeaveBalance> {
    return this.repository.save(balance);
  }

  saveMany(balances: LeaveBalance[]): Promise<LeaveBalance[]> {
    return this.repository.save(balances);
  }
}
