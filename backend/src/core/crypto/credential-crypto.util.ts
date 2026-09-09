import { createCipheriv, createDecipheriv, randomBytes } from 'crypto';

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 12;

/** Encrypts a real, working secret (e.g. a mailbox password) for storage at
 * rest, using the app-wide EMAIL_CREDENTIAL_KEY. Output packs iv + authTag +
 * ciphertext into one base64 string so it fits a single text column. */
export function encryptCredential(plainText: string, hexKey: string): string {
  const key = Buffer.from(hexKey, 'hex');
  const iv = randomBytes(IV_LENGTH);
  const cipher = createCipheriv(ALGORITHM, key, iv);
  const ciphertext = Buffer.concat([
    cipher.update(plainText, 'utf8'),
    cipher.final(),
  ]);
  const authTag = cipher.getAuthTag();
  return Buffer.concat([iv, authTag, ciphertext]).toString('base64');
}

export function decryptCredential(packed: string, hexKey: string): string {
  const key = Buffer.from(hexKey, 'hex');
  const buffer = Buffer.from(packed, 'base64');
  const iv = buffer.subarray(0, IV_LENGTH);
  const authTag = buffer.subarray(IV_LENGTH, IV_LENGTH + 16);
  const ciphertext = buffer.subarray(IV_LENGTH + 16);
  const decipher = createDecipheriv(ALGORITHM, key, iv);
  decipher.setAuthTag(authTag);
  return Buffer.concat([
    decipher.update(ciphertext),
    decipher.final(),
  ]).toString('utf8');
}
