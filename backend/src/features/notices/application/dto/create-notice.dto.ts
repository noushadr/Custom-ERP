import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class CreateNoticeDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  title: string;

  @IsString()
  @IsNotEmpty()
  body: string;
}
