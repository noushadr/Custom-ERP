import { IsDateString, IsNotEmpty, IsString, IsUUID } from 'class-validator';

export class SubmitLeaveRequestDto {
  @IsUUID()
  leaveTypeId: string;

  @IsDateString()
  startDate: string;

  @IsDateString()
  endDate: string;

  @IsString()
  @IsNotEmpty()
  reason: string;
}
