import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { NoticeDisplayDuration } from '../../domain/enums/notice-display-duration.enum';

export class CreateNoticeDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  title: string;

  @IsString()
  @IsNotEmpty()
  body: string;

  /** How long the notice stays visible; omitted means always. */
  @IsOptional()
  @IsEnum(NoticeDisplayDuration)
  displayDuration?: NoticeDisplayDuration;
}
