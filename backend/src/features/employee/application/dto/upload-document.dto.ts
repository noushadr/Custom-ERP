import { IsEnum, IsOptional } from 'class-validator';
import { DocumentType } from '../../domain/enums/document-type.enum';

export class UploadDocumentDto {
  @IsOptional()
  @IsEnum(DocumentType)
  documentType?: DocumentType;
}
