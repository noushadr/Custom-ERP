import {
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { definedFieldsOnly } from '../../../core/utils/defined-fields-only.util';
import { Department } from '../domain/entities/department.entity';
import {
  DEPARTMENT_REPOSITORY,
  type DepartmentRepository,
} from '../domain/repositories/department-repository.interface';
import { CreateDepartmentDto } from './dto/create-department.dto';
import { UpdateDepartmentDto } from './dto/update-department.dto';

const FOREIGN_KEY_VIOLATION = '23503';

@Injectable()
export class DepartmentsService {
  constructor(
    @Inject(DEPARTMENT_REPOSITORY)
    private readonly departmentRepository: DepartmentRepository,
  ) {}

  findAll(includeArchived = false): Promise<Department[]> {
    return this.departmentRepository.findAll(includeArchived);
  }

  create(dto: CreateDepartmentDto): Promise<Department> {
    const department = new Department();
    department.name = dto.name;
    department.description = dto.description;
    department.headEmployeeId = dto.headEmployeeId;
    return this.departmentRepository.save(department);
  }

  async update(id: string, dto: UpdateDepartmentDto): Promise<Department> {
    const department = await this.departmentRepository.findById(id);
    if (!department) throw new NotFoundException('Department not found');

    Object.assign(department, definedFieldsOnly(dto));
    return this.departmentRepository.save(department);
  }

  async remove(id: string): Promise<void> {
    const department = await this.departmentRepository.findById(id);
    if (!department) throw new NotFoundException('Department not found');

    try {
      await this.departmentRepository.remove(department);
    } catch (error) {
      if (this.isForeignKeyViolation(error)) {
        throw new ConflictException(
          'Cannot delete a department that still has employees or teams ' +
            'assigned. Archive it instead.',
        );
      }
      throw error;
    }
  }

  private isForeignKeyViolation(error: unknown): boolean {
    const code =
      (error as { code?: string })?.code ??
      (error as { driverError?: { code?: string } })?.driverError?.code;
    return code === FOREIGN_KEY_VIOLATION;
  }
}
