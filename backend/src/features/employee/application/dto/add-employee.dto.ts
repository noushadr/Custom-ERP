import {
  IsDateString,
  IsEmail,
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MinLength,
} from 'class-validator';
import { WorkMode } from '../../domain/enums/work-mode.enum';

export class AddEmployeeDto {
  @IsEmail()
  @Matches(/@zeracreative\.com$/i, {
    message: 'Company email must be a @zeracreative.com address',
  })
  companyEmail: string;

  /** Set directly by the HR/Admin adding this employee — there is no
   * self-signup, so nobody else ever picks this account's initial
   * password. */
  @IsString()
  @MinLength(8, { message: 'Password must be at least 8 characters' })
  password: string;

  @IsString()
  @MinLength(1)
  firstName: string;

  @IsString()
  @MinLength(1)
  lastName: string;

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
  @IsDateString()
  joiningDate?: string;

  /** Every employee goes through probation, but not for a fixed company-wide
   * duration — defaults to 3 months from `joiningDate` when omitted (see
   * `EmployeesService.addEmployee`), freely adjustable afterward per employee. */
  @IsOptional()
  @IsDateString()
  probationEndDate?: string;

  /** Determines which onboarding checklist items apply — defaults to
   * on-site, matching the Employee entity's own column default. */
  @IsOptional()
  @IsEnum(WorkMode)
  workMode?: WorkMode;

  /** Overrides the auto-generated sequence — used only when importing
   * historical records that must keep a pre-existing employee code. */
  @IsOptional()
  @IsString()
  @Matches(/^ZC-\d+$/, {
    message: 'employeeCode must match the ZC-<digits> format',
  })
  employeeCode?: string;
}
