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
import { ProjectPaymentStatus } from '../../domain/enums/project-payment-status.enum';
import { ProjectStatus } from '../../domain/enums/project-status.enum';
import { ProjectType } from '../../domain/enums/project-type.enum';

export class UpdateProjectDto {
  @IsOptional()
  @IsString()
  clientId?: string;

  @IsOptional()
  @IsString()
  @MinLength(2)
  name?: string;

  @IsOptional()
  @IsEnum(ProjectType)
  type?: ProjectType;

  @IsOptional()
  @IsEnum(ProjectStatus)
  status?: ProjectStatus;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @IsDateString()
  renewalDate?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  originalClientPrice?: number;

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
  @IsEnum(ProjectPaymentStatus)
  paymentStatus?: ProjectPaymentStatus;

  @IsOptional()
  @IsNumber()
  @Min(0)
  amountPaid?: number;

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
