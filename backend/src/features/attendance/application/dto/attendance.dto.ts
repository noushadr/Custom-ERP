import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  Max,
  Min,
} from 'class-validator';

export class UpdateAttendanceSettingsDto {
  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, { message: 'Use HH:mm, e.g. 11:00' })
  shiftStart: string;

  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, { message: 'Use HH:mm, e.g. 19:00' })
  shiftEnd: string;

  @IsInt()
  @Min(0)
  @Max(180)
  graceMinutes: number;
}

export class IgnoreDeviceUserDto {
  @IsString()
  deviceUserId: string;

  @IsBoolean()
  ignored: boolean;
}

export class SetAttendanceMappingDto {
  @IsUUID()
  employeeId: string;

  /** The machine's user id ("AC-No."), or null/omitted to unlink. */
  @IsOptional()
  @IsString()
  deviceUserId?: string | null;
}
