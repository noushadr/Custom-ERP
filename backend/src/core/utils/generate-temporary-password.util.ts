import { randomBytes } from 'crypto';

// Excludes visually ambiguous characters (0/O, 1/l/I).
const CHARSET = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';

export function generateTemporaryPassword(length = 12): string {
  const bytes = randomBytes(length);
  return Array.from(bytes, (byte) => CHARSET[byte % CHARSET.length]).join('');
}
