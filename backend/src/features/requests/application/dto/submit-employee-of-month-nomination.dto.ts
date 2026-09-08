import { IsNotEmpty, IsString, IsUUID } from 'class-validator';

export class SubmitEmployeeOfMonthNominationDto {
  @IsUUID()
  nomineeEmployeeId: string;

  @IsString()
  @IsNotEmpty()
  reason: string;
}
