import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PayrollRun } from '../../domain/entities/payroll-run.entity';
import { PayrollRunRepository } from '../../domain/repositories/payroll-run-repository.interface';

@Injectable()
export class TypeOrmPayrollRunRepository implements PayrollRunRepository {
  constructor(
    @InjectRepository(PayrollRun)
    private readonly repository: Repository<PayrollRun>,
  ) {}

  findAll(): Promise<PayrollRun[]> {
    return this.repository.find({ order: { year: 'DESC', month: 'DESC' } });
  }

  findById(id: string): Promise<PayrollRun | null> {
    return this.repository.findOne({ where: { id } });
  }

  findByMonthYear(month: number, year: number): Promise<PayrollRun | null> {
    return this.repository.findOne({ where: { month, year } });
  }

  save(run: PayrollRun): Promise<PayrollRun> {
    return this.repository.save(run);
  }
}
