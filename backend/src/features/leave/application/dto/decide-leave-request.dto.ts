import { IsOptional, IsString } from 'class-validator';

/** Used for both approve and reject — the spec calls for optional comments
 * on either decision, not just on rejection. */
export class DecideLeaveRequestDto {
  @IsOptional()
  @IsString()
  comment?: string;
}
