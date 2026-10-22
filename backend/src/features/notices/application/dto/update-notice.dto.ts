import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { NoticeDisplayDuration } from '../../domain/enums/notice-display-duration.enum';

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

  /** When present, restarts the display window from now (so an expired
   * notice can be brought back); omitted leaves the current expiry alone. */
  @IsOptional()
  @IsEnum(NoticeDisplayDuration)
  displayDuration?: NoticeDisplayDuration;
}
