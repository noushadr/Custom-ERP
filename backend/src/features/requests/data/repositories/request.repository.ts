import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EmployeeRequest } from '../../domain/entities/employee-request.entity';
import { RequestStatus } from '../../domain/enums/request-status.enum';
import { RequestRepository } from '../../domain/repositories/request-repository.interface';

@Injectable()
export class TypeOrmRequestRepository implements RequestRepository {
  constructor(
    @InjectRepository(EmployeeRequest)
    private readonly repository: Repository<EmployeeRequest>,
  ) {}

  findById(id: string): Promise<EmployeeRequest | null> {
    return this.repository.findOne({
      where: { id },
      relations: { employee: true },
    });
  }

  findByEmployeeId(employeeId: string): Promise<EmployeeRequest[]> {
    return this.repository.find({
      where: { employeeId },
      relations: { employee: true },
      order: { createdAt: 'DESC' },
    });
  }

  findByStatus(status: RequestStatus): Promise<EmployeeRequest[]> {
    return this.repository.find({
      where: { status },
      relations: { employee: true },
      order: { createdAt: 'ASC' },
    });
  }

  save(request: EmployeeRequest): Promise<EmployeeRequest> {
    return this.repository.save(request);
  }
}
