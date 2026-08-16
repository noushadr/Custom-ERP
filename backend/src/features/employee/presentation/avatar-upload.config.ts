import { randomUUID } from 'crypto';
import { mkdirSync } from 'fs';
import { extname, join } from 'path';
import { BadRequestException } from '@nestjs/common';
import { diskStorage } from 'multer';
import type { MulterOptions } from '@nestjs/platform-express/multer/interfaces/multer-options.interface';

export const AVATAR_UPLOAD_DIR = join(process.cwd(), 'uploads', 'avatars');
const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024;

export const avatarUploadOptions: MulterOptions = {
  storage: diskStorage({
    destination: (_req, _file, callback) => {
      mkdirSync(AVATAR_UPLOAD_DIR, { recursive: true });
      callback(null, AVATAR_UPLOAD_DIR);
    },
    filename: (_req, file, callback) => {
      callback(null, `${randomUUID()}${extname(file.originalname)}`);
    },
  }),
  limits: { fileSize: MAX_FILE_SIZE_BYTES },
  fileFilter: (_req, file, callback) => {
    if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      callback(
        new BadRequestException('Only JPEG, PNG, or WEBP images are allowed'),
        false,
      );
      return;
    }
    callback(null, true);
  },
};
