import { IsString, MinLength } from 'class-validator';

export class VerifyModulePinDto {
  @IsString()
  @MinLength(1)
  pin: string;
}
