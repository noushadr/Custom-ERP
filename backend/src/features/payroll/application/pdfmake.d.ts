// pdfmake 0.2.x ships no TypeScript types and there's no matching @types
// package for this version — a minimal local declaration covering only what
// `payslip.generator.ts` actually uses, instead of reaching for `any`.
declare module 'pdfmake' {
  import type { Readable } from 'stream';

  interface PdfMakeFontDescriptor {
    normal: string;
    bold?: string;
    italics?: string;
    bolditalics?: string;
  }

  interface PdfKitDocument extends Readable {
    end(): void;
  }

  export default class PdfPrinter {
    constructor(fonts: Record<string, PdfMakeFontDescriptor>);
    createPdfKitDocument(docDefinition: unknown): PdfKitDocument;
  }
}
