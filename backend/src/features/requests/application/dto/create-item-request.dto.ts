import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class CreateItemRequestDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  itemName: string;

  @IsString()
  @IsNotEmpty()
  purpose: string;
}
