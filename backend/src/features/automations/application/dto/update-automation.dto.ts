import { IsBoolean, IsInt, IsOptional, Max, Min } from 'class-validator';

export class UpdateAutomationDto {
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(90)
  daysBefore?: number;
}
