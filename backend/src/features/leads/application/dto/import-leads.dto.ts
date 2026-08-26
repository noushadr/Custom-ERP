import { Type } from 'class-transformer';
import { ArrayMinSize, IsArray, ValidateNested } from 'class-validator';
import { CreateLeadDto } from './create-lead.dto';

/** Bulk-create endpoint's request shape — every row goes through the exact
 * same `CreateLeadDto` validation a single `POST /leads` would (required
 * date/fullName, well-formed email if present, etc.), via the app's global
 * `ValidationPipe`. The frontend is expected to have already parsed and
 * previewed the pasted data — this only ever receives rows the user has
 * already seen validate cleanly, so there's no partial-success/per-row
 * error reporting to design here. */
export class ImportLeadsDto {
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CreateLeadDto)
  leads: CreateLeadDto[];
}
