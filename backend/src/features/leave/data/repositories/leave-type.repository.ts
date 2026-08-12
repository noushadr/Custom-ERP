import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { LeaveType } from '../../domain/entities/leave-type.entity';
import { LeaveTypeRepository } from '../../domain/repositories/leave-type-repository.interface';

@Injectable()
export class TypeOrmLeaveTypeRepository implements LeaveTypeRepository {
  constructor(
    @InjectRepository(LeaveType)
    private readonly repository: Repository<LeaveType>,
  ) {}

  findAll(includeArchived = false): Promise<LeaveType[]> {
    return this.repository.find({
      where: includeArchived ? {} : { isArchived: false },
      order: { name: 'ASC' },
    });
  }

  findById(id: string): Promise<LeaveType | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(leaveType: LeaveType): Promise<LeaveType> {
    return this.repository.save(leaveType);
  }

  async remove(leaveType: LeaveType): Promise<void> {
    await this.repository.remove(leaveType);
  }
}
