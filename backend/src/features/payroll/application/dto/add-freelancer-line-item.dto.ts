import { IsNumber, IsOptional, IsString, IsUUID, Min } from 'class-validator';

export class AddFreelancerLineItemDto {
  @IsUUID()
  freelancerId: string;

  /** This month's pay for the freelancer — a plain directly-entered
   * amount, since freelancers have no SalaryRecord to snapshot from. */
  @IsNumber()
  @Min(0)
  baseSalary: number;

  @IsOptional()
  @IsString()
  notes?: string;
}
