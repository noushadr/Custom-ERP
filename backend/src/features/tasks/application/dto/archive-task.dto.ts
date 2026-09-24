import { IsBoolean } from 'class-validator';

export class ArchiveTaskDto {
  @IsBoolean()
  isArchived: boolean;
}
