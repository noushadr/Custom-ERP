import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

/** Same shape as `CreateGoalDto` minus `employeeId` — an employee creating a
 * goal for themselves never names a target; `GoalsService.createForSelf`
 * always resolves it from the caller's own identity. */
export class CreateSelfGoalDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  title: string;

  @IsOptional()
  @IsString()
  description?: string;
}
