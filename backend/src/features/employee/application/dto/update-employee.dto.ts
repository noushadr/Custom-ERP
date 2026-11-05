import {
  IsDateString,
  IsEmail,
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
} from 'class-validator';
import { EmploymentStatus } from '../../domain/enums/employment-status.enum';
import { EmploymentType } from '../../domain/enums/employment-type.enum';
import { WorkMode } from '../../domain/enums/work-mode.enum';
import { EMPLOYEE_CODE_PATTERN } from '../employee-code.util';
import { UpdateMyProfileDto } from './update-my-profile.dto';

/** Fields an HR/Admin can change, in addition to everything an employee can edit on their own profile. */
export class UpdateEmployeeDto extends UpdateMyProfileDto {
  /** The employee ID (ZC-073). Only changeable within 30 days of the employee
   * being added, and never to an ID any other employee — past or present —
   * has had; the service enforces both. */
  @IsOptional()
  @Matches(EMPLOYEE_CODE_PATTERN, {
    message: 'Employee ID must look like ZC-073',
  })
  employeeCode?: string;

  @IsOptional()
  @IsEmail()
  companyEmail?: string;

  @IsOptional()
  @IsString()
  firstName?: string;

  @IsOptional()
  @IsString()
  lastName?: string;

  @IsOptional()
  @IsString()
  designation?: string;

  @IsOptional()
  @IsUUID()
  departmentId?: string;

  @IsOptional()
  @IsUUID()
  reportingManagerId?: string;

  @IsOptional()
  @IsEnum(EmploymentType)
  employmentType?: EmploymentType;

  @IsOptional()
  @IsEnum(EmploymentStatus)
  employmentStatus?: EmploymentStatus;

  @IsOptional()
  @IsEnum(WorkMode)
  workMode?: WorkMode;

  @IsOptional()
  @IsDateString()
  joiningDate?: string;

  @IsOptional()
  @IsDateString()
  dateOfLeaving?: string;

  @IsOptional()
  @IsDateString()
  probationEndDate?: string;
}
