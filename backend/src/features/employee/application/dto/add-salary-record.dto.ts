import {
  IsDateString,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class AddSalaryRecordDto {
  @IsNumber()
  @Min(0)
  amount: number;

  @IsDateString()
  effectiveDate: string;

  @IsOptional()
  @IsString()
  note?: string;
}
