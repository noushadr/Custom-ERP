import { IsInt, IsNotEmpty, IsString, Max, Min } from 'class-validator';

export class AddEducationRecordDto {
  @IsString()
  @IsNotEmpty()
  degree: string;

  @IsString()
  @IsNotEmpty()
  institution: string;

  @IsInt()
  @Min(1950)
  @Max(2100)
  yearCompleted: number;
}
