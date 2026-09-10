import {
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class UpdateGoalDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  title?: string;

  @IsOptional()
  @IsString()
  description?: string;

  /** Admin/HR only — `GoalsService.update` applies this, `updateAsManager`
   * (Team Lead) silently ignores it even if sent. */
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  achievementPercentage?: number;
}
