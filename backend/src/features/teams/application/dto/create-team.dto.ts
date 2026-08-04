import { IsOptional, IsString, IsUUID, MinLength } from 'class-validator';

export class CreateTeamDto {
  @IsString()
  @MinLength(2)
  name: string;

  @IsUUID()
  departmentId: string;

  @IsOptional()
  @IsUUID()
  leadEmployeeId?: string;
}
