import {
  IsBoolean,
  IsEmail,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
  MinLength,
} from 'class-validator';

/** What Admin/HR (or the employee themselves) types in after creating the
 * real mailbox in cPanel — the mailbox's own live credentials, not
 * anything the app generates. */
export class SetupEmailAccountDto {
  @IsEmail()
  emailAddress: string;

  @IsString()
  @MinLength(1)
  password: string;

  @IsString()
  @MinLength(1)
  smtpHost: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(65535)
  smtpPort?: number;

  @IsString()
  @MinLength(1)
  imapHost: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(65535)
  imapPort?: number;

  @IsOptional()
  @IsBoolean()
  smtpSecure?: boolean;
}
