import { IsDateString, IsOptional, IsString, MinLength } from 'class-validator';

export class UpdateHolidayDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  name?: string;

  @IsOptional()
  @IsDateString()
  date?: string;
}
