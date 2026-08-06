import { EmployeeDocument } from '../domain/entities/employee-document.entity';
import { DocumentResponse } from './document-response.interface';

export function toDocumentResponse(
  document: EmployeeDocument,
): DocumentResponse {
  return {
    id: document.id,
    fileName: document.fileName,
    fileSize: document.fileSize,
    url: document.filePath,
    uploadedAt: document.createdAt,
  };
}
