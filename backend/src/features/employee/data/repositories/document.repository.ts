import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EmployeeDocument } from '../../domain/entities/employee-document.entity';
import { DocumentRepository } from '../../domain/repositories/document-repository.interface';

@Injectable()
export class TypeOrmDocumentRepository implements DocumentRepository {
  constructor(
    @InjectRepository(EmployeeDocument)
    private readonly repository: Repository<EmployeeDocument>,
  ) {}

  findByEmployeeId(employeeId: string): Promise<EmployeeDocument[]> {
    return this.repository.find({
      where: { employeeId },
      order: { createdAt: 'DESC' },
    });
  }

  findById(id: string): Promise<EmployeeDocument | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(document: EmployeeDocument): Promise<EmployeeDocument> {
    return this.repository.save(document);
  }

  async remove(document: EmployeeDocument): Promise<void> {
    await this.repository.remove(document);
  }
}
