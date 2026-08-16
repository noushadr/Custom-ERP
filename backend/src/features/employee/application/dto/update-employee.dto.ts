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
import { UpdateMyProfileDto } from './update-my-profile.dto';

/** Fields an HR/Admin can change, in addition to everything an employee can edit on their own profile. */
export class UpdateEmployeeDto extends UpdateMyProfileDto {
  @IsOptional()
  @IsEmail()
  @Matches(/^[a-z]+\.[a-z]+@zeracreative\.com$/, {
    message:
      'Company email must match the firstname.lastname@zeracreative.com format',
  })
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
}
