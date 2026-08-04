import {
  ConflictException,
  Inject,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { User } from '../../authentication/domain/entities/user.entity';
import { UserStatus } from '../../authentication/domain/enums/user-status.enum';
import {
  ROLE_REPOSITORY,
  type RoleRepository,
} from '../../authentication/domain/repositories/role-repository.interface';
import {
  USER_REPOSITORY,
  type UserRepository,
} from '../../authentication/domain/repositories/user-repository.interface';
import { Employee } from '../domain/entities/employee.entity';
import {
  EMPLOYEE_REPOSITORY,
  type EmployeeRepository,
} from '../domain/repositories/employee-repository.interface';
import { EmployeeResponse } from './employee-response.interface';
import { toEmployeeResponse } from './employee.mapper';
import { generateTemporaryPassword } from './generate-temporary-password.util';
import { InviteEmployeeDto } from './dto/invite-employee.dto';
import { UpdateEmployeeDto } from './dto/update-employee.dto';
import { UpdateMyProfileDto } from './dto/update-my-profile.dto';

const DEFAULT_INVITE_ROLE = 'Employee';

@Injectable()
export class EmployeesService {
  constructor(
    @Inject(EMPLOYEE_REPOSITORY)
    private readonly employeeRepository: EmployeeRepository,
    @Inject(USER_REPOSITORY) private readonly userRepository: UserRepository,
    @Inject(ROLE_REPOSITORY) private readonly roleRepository: RoleRepository,
  ) {}

  async invite(
    dto: InviteEmployeeDto,
  ): Promise<{ employee: EmployeeResponse; temporaryPassword: string }> {
    const existingUser = await this.userRepository.findByEmail(
      dto.companyEmail,
    );
    if (existingUser) {
      throw new ConflictException('A user with this email already exists');
    }

    const employeeRole =
      await this.roleRepository.findByName(DEFAULT_INVITE_ROLE);
    if (!employeeRole) {
      throw new InternalServerErrorException(
        `Default "${DEFAULT_INVITE_ROLE}" role is not seeded`,
      );
    }

    const temporaryPassword = generateTemporaryPassword();
    const passwordHash = await bcrypt.hash(temporaryPassword, 10);

    const user = new User();
    user.email = dto.companyEmail;
    user.passwordHash = passwordHash;
    user.roleId = employeeRole.id;
    user.role = employeeRole;
    user.status = UserStatus.PENDING_INVITE;
    const savedUser = await this.userRepository.save(user);

    const employee = new Employee();
    employee.userId = savedUser.id;
    employee.employeeCode = await this.generateEmployeeCode();
    employee.firstName = dto.firstName;
    employee.lastName = dto.lastName;
    employee.designation = dto.designation;
    employee.departmentId = dto.departmentId;
    employee.teamId = dto.teamId;
    employee.reportingManagerId = dto.reportingManagerId;
    employee.joiningDate =
      dto.joiningDate ?? new Date().toISOString().slice(0, 10);
    employee.skills = [];
    employee.certifications = [];

    const savedEmployee = await this.employeeRepository.save(employee);
    const reloaded = await this.employeeRepository.findById(savedEmployee.id);

    return {
      employee: toEmployeeResponse(reloaded!),
      temporaryPassword,
    };
  }

  async findAll(): Promise<EmployeeResponse[]> {
    const employees = await this.employeeRepository.findAll();
    return employees.map(toEmployeeResponse);
  }

  async findById(id: string): Promise<EmployeeResponse> {
    const employee = await this.employeeRepository.findById(id);
    if (!employee) throw new NotFoundException('Employee not found');
    return toEmployeeResponse(employee);
  }

  async findByUserId(userId: string): Promise<EmployeeResponse> {
    const employee = await this.employeeRepository.findByUserId(userId);
    if (!employee) throw new NotFoundException('Employee profile not found');
    return toEmployeeResponse(employee);
  }

  async updateSelf(
    userId: string,
    dto: UpdateMyProfileDto,
  ): Promise<EmployeeResponse> {
    const employee = await this.employeeRepository.findByUserId(userId);
    if (!employee) throw new NotFoundException('Employee profile not found');

    Object.assign(employee, dto);
    const saved = await this.employeeRepository.save(employee);
    const reloaded = await this.employeeRepository.findById(saved.id);
    return toEmployeeResponse(reloaded!);
  }

  async update(id: string, dto: UpdateEmployeeDto): Promise<EmployeeResponse> {
    const employee = await this.employeeRepository.findById(id);
    if (!employee) throw new NotFoundException('Employee not found');

    Object.assign(employee, dto);
    const saved = await this.employeeRepository.save(employee);
    const reloaded = await this.employeeRepository.findById(saved.id);
    return toEmployeeResponse(reloaded!);
  }

  private async generateEmployeeCode(): Promise<string> {
    const count = await this.employeeRepository.count();
    return `ZC-${String(count + 1).padStart(5, '0')}`;
  }
}
