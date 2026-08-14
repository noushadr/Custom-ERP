import {
  IsDateString,
  IsEmail,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MinLength,
} from 'class-validator';

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
  teamId?: string;

  @IsOptional()
  @IsUUID()
  reportingManagerId?: string;

  @IsOptional()
  @IsDateString()
  joiningDate?: string;

  /** Overrides the auto-generated sequence — used only when importing
   * historical records that must keep a pre-existing employee code. */
  @IsOptional()
  @IsString()
  @Matches(/^ZC-\d+$/, {
    message: 'employeeCode must match the ZC-<digits> format',
  })
  employeeCode?: string;
}
