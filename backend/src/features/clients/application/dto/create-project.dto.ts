import {
  IsArray,
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  MinLength,
} from 'class-validator';
import { ProjectStatus } from '../../domain/enums/project-status.enum';
import { ProjectType } from '../../domain/enums/project-type.enum';

export class CreateProjectDto {
  @IsString()
  clientId: string;

  @IsString()
  @MinLength(2)
  name: string;

  @IsEnum(ProjectType)
  type: ProjectType;

  @IsOptional()
  @IsEnum(ProjectStatus)
  status?: ProjectStatus;

  @IsDateString()
  startDate: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @IsDateString()
  renewalDate?: string;

  @IsNumber()
  @Min(0)
  originalClientPrice: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  deductionRate?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  cost?: number;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  assignedEmployeeIds?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  targetDepartmentIds?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  serviceIds?: string[];
}
