import { IsOptional, IsString, IsNotEmpty } from 'class-validator';

export class CreateAssetDto {
  @IsString()
  @IsNotEmpty()
  name: string;

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
