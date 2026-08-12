import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class UpdateAssetDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  name?: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsString()
  serialNumber?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}
