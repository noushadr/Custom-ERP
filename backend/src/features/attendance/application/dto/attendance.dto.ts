import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  Max,
  MaxLength,
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

  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, { message: 'Use HH:mm, e.g. 11:30' })
  hoursCutAfter: string;

  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, { message: 'Use HH:mm, e.g. 10:30' })
  hoursCutFrom: string;
}

export class AddWfhDayDto {
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'Use a date like 2026-11-12' })
  date: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  note?: string;
}

export class SetWfhAttendanceDto {
  /** Everyone HR marks as having worked that day (replaces the old set). */
  @IsArray()
  @ArrayMaxSize(500)
  @IsUUID('all', { each: true })
  employeeIds: string[];
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
