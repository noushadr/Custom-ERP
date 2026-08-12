import { IsInt, IsNotEmpty, IsNumber, IsString, IsUUID } from 'class-validator';

export class AdjustLeaveBalanceDto {
  @IsUUID()
  leaveTypeId: string;

  @IsInt()
  year: number;

  /** Positive to grant extra days, negative to deduct. */
  @IsNumber()
  deltaDays: number;

  @IsString()
  @IsNotEmpty()
  reason: string;
}
