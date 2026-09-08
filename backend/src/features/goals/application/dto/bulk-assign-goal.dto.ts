import { IsNotEmpty, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

/** Creates the same goal for every currently-active employee in one
 * department in a single call — Admin/HR only (see `GoalsService.
 * bulkAssignToDepartment`). */
export class BulkAssignGoalDto {
  @IsUUID()
  departmentId: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  title: string;

  @IsOptional()
  @IsString()
  description?: string;
}
