import { IsOptional, IsString, MinLength } from 'class-validator';

export class CreateFreelancerDto {
  @IsString()
  @MinLength(2)
  fullName: string;

  @IsOptional()
  @IsString()
  role?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}
