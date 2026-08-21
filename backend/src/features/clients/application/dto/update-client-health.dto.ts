import { IsArray, IsEnum, IsOptional, IsString } from 'class-validator';
import { ClientHealthFactor } from '../../domain/enums/client-health-factor.enum';
import { ClientHealthStatus } from '../../domain/enums/client-health-status.enum';

export class UpdateClientHealthDto {
  @IsEnum(ClientHealthStatus)
  status: ClientHealthStatus;

  @IsOptional()
  @IsArray()
  @IsEnum(ClientHealthFactor, { each: true })
  factors?: ClientHealthFactor[];

  @IsOptional()
  @IsString()
  notes?: string;
}
