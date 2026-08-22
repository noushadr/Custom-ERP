import { IsBoolean, IsOptional, IsString } from 'class-validator';

export class SetChecklistItemCompletedDto {
  @IsBoolean()
  isCompleted: boolean;

  @IsOptional()
  @IsString()
  note?: string;
}
