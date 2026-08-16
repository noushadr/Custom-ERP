import { IsDateString, IsString, MinLength } from 'class-validator';

export class CreateHolidayDto {
  @IsString()
  @MinLength(2)
  name: string;

  @IsDateString()
  date: string;
}
