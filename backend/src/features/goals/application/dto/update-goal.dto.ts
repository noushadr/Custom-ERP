import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateGoalDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  title?: string;

  @IsOptional()
  @IsString()
  description?: string;
}
