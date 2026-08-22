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

export class InviteEmployeeDto {
  @IsEmail()
  @Matches(/^[a-z]+\.[a-z]+@zeracreative\.com$/, {
    message:
      'Company email must match the firstname.lastname@zeracreative.com format',
  })
  companyEmail: string;

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
