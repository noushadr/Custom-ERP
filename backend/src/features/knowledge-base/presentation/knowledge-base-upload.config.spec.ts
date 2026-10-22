import { join, resolve } from 'path';
import {
  KNOWLEDGE_BASE_UPLOAD_DIR,
  mimeTypeForExtension,
  storedFilePath,
} from './knowledge-base-upload.config';

describe('mimeTypeForExtension', () => {
  it.each([
    ['policy.pdf', 'application/pdf'],
    ['POLICY.PDF', 'application/pdf'],
    ['deck.pptx', 'application/vnd.openxmlformats-officedocument.presentationml.presentation'],
    ['sheet.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'],
    ['notes.txt', 'text/plain'],
    ['photo.jpeg', 'image/jpeg'],
    ['photo.JPG', 'image/jpeg'],
  ])('maps %s to %s', (name, mime) => {
    expect(mimeTypeForExtension(name)).toBe(mime);
  });

  it.each([
    'page.html',
    'page.htm',
    'logo.svg',
    'run.exe',
    'script.js',
    'archive.zip',
    'no-extension',
    'pdf',
    'trick.pdf.html',
  ])('rejects %s', (name) => {
    expect(mimeTypeForExtension(name)).toBeNull();
  });
});

describe('storedFilePath', () => {
  it('resolves a plain stored name inside the private KB folder', () => {
    expect(storedFilePath('abc.pdf')).toBe(
      join(KNOWLEDGE_BASE_UPLOAD_DIR, 'abc.pdf'),
    );
  });

  it('never escapes the KB folder, even for a hostile stored name', () => {
    for (const hostile of [
      '../../etc/passwd',
      '..\\..\\Windows\\win.ini',
      '/etc/passwd',
      'C:\\Windows\\win.ini',
    ]) {
      const resolved = resolve(storedFilePath(hostile));
      expect(resolved.startsWith(resolve(KNOWLEDGE_BASE_UPLOAD_DIR))).toBe(true);
    }
  });

  it('is not under the statically served uploads folder', () => {
    expect(KNOWLEDGE_BASE_UPLOAD_DIR).not.toContain(join('uploads'));
  });
});
