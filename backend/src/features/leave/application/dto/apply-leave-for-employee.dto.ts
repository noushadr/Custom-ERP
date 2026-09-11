import { IsDateString, IsNotEmpty, IsString, IsUUID } from 'class-validator';

/** HR/Admin applying leave directly on an employee's behalf — same shape as
 * [SubmitLeaveRequestDto] minus the employee (that comes from the URL
 * param instead, since the actor isn't the employee themselves here). */
export class ApplyLeaveForEmployeeDto {
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
