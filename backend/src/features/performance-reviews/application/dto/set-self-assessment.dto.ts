import { IsNotEmpty, IsString } from 'class-validator';

export class SetSelfAssessmentDto {
  /** Mandatory — the employee must give their own feedback. */
  @IsString()
  @IsNotEmpty()
  comments: string;
}
