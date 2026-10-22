import { randomUUID } from 'crypto';
import { mkdirSync } from 'fs';
import { basename, extname, join } from 'path';
import { BadRequestException } from '@nestjs/common';
import { diskStorage } from 'multer';
import type { MulterOptions } from '@nestjs/platform-express/multer/interfaces/multer-options.interface';

/** Deliberately NOT under `uploads/`: that folder is served statically to
 * anyone who has the URL, which would bypass an article's role/department
 * visibility. Knowledge Base files are only reachable through the
 * authenticated, visibility-checked download endpoints. */
export const KNOWLEDGE_BASE_UPLOAD_DIR = join(
  process.cwd(),
  'storage',
  'knowledge-base',
);

/** The one place the served Content-Type comes from — keyed by the (lower-
 * cased) file extension we saved, never by what the uploader's browser
 * claimed, so an uploaded file can't pose as a different type. No HTML, SVG
 * or script types are accepted. */
const MIME_BY_EXTENSION: Record<string, string> = {
  '.pdf': 'application/pdf',
  '.doc': 'application/msword',
  '.docx':
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  '.xls': 'application/vnd.ms-excel',
  '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  '.ppt': 'application/vnd.ms-powerpoint',
  '.pptx':
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  '.csv': 'text/csv',
  '.txt': 'text/plain',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
};

const MAX_FILE_SIZE_BYTES = 25 * 1024 * 1024;

export const KNOWLEDGE_BASE_ALLOWED_EXTENSIONS = Object.keys(MIME_BY_EXTENSION);

export function mimeTypeForExtension(fileName: string): string | null {
  return MIME_BY_EXTENSION[extname(fileName).toLowerCase()] ?? null;
}

/** Resolves a stored file name to its absolute path, refusing anything that
 * isn't a bare file name (defence in depth: the name always comes from our
 * own database, but it is never allowed to contain a path). */
export function storedFilePath(storedFileName: string): string {
  return join(KNOWLEDGE_BASE_UPLOAD_DIR, basename(storedFileName));
}

export const knowledgeBaseUploadOptions: MulterOptions = {
  storage: diskStorage({
    destination: (_req, _file, callback) => {
      mkdirSync(KNOWLEDGE_BASE_UPLOAD_DIR, { recursive: true });
      callback(null, KNOWLEDGE_BASE_UPLOAD_DIR);
    },
    filename: (_req, file, callback) => {
      callback(
        null,
        `${randomUUID()}${extname(file.originalname).toLowerCase()}`,
      );
    },
  }),
  limits: { fileSize: MAX_FILE_SIZE_BYTES },
  fileFilter: (_req, file, callback) => {
    if (!mimeTypeForExtension(file.originalname)) {
      callback(
        new BadRequestException(
          'Unsupported file type. Upload a PDF, Word, Excel, PowerPoint, ' +
            'CSV, text, or image (PNG/JPEG/WEBP) file.',
        ),
        false,
      );
      return;
    }
    callback(null, true);
  },
};
