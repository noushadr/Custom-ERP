import { IsBoolean, IsOptional, IsString, MinLength } from 'class-validator';

export class UpdateServiceDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  name?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsBoolean()
  isArchived?: boolean;
}
