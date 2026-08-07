import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { DocumentType } from '../enums/document-type.enum';
import { Employee } from './employee.entity';

@Entity('employee_documents')
export class EmployeeDocument extends BaseEntity {
  @Column()
  employeeId: string;

  @ManyToOne(() => Employee, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'employeeId' })
  employee: Employee;

  @Column({
    type: 'enum',
    enum: DocumentType,
    default: DocumentType.OTHER,
  })
  documentType: DocumentType;

  /** Original filename, shown to the user (the file on disk is a random uuid). */
  @Column()
  fileName: string;

  /** Path relative to the server root, e.g. /uploads/documents/<uuid>.pdf */
  @Column()
  filePath: string;

  @Column({ type: 'int' })
  fileSize: number;
}
