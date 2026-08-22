import { IsString } from 'class-validator';

export class SetSelfAssessmentDto {
  @IsString()
  comments: string;
}
