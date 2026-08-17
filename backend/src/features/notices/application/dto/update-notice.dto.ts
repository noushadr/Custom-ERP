import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateNoticeDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  title?: string;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  body?: string;
}
