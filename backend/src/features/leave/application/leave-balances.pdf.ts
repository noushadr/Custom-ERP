import PdfPrinter from 'pdfmake';
import { EmployeeLeaveOverviewResponse } from './employee-leave-overview-response.interface';
import { ZERA_LOGO_BASE64 } from '../../payroll/application/zera-logo.base64';

const BRAND_PRIMARY = '#6C5DD3';
const BRAND_TEXT_SECONDARY = '#625F73';
const BRAND_BORDER = '#E3E1F0';

const printer = new PdfPrinter({
  Helvetica: {
    normal: 'Helvetica',
    bold: 'Helvetica-Bold',
    italics: 'Helvetica-Oblique',
    bolditalics: 'Helvetica-BoldOblique',
  },
});

const num = (value: number): string => String(Number(value.toFixed(2)));

/** Every active employee's leave for the year: remaining / total per leave
 * type, plus overall totals — the same figures as the on-screen table. */
export function generateLeaveBalancesPdf(
  employees: EmployeeLeaveOverviewResponse[],
  year: number,
): Promise<Buffer> {
  const typeNames = (employees[0]?.balances ?? []).map((b) => b.leaveTypeName);
  const header = [
    'Employee',
    'Department',
    ...typeNames,
    'Total',
    'Remaining',
  ].map((text) => ({ text, bold: true, color: BRAND_PRIMARY }));

  const body =
    employees.length === 0
      ? [{ text: 'No active employees.', color: BRAND_TEXT_SECONDARY }]
      : [
          {
            table: {
              headerRows: 1,
              widths: [
                '*',
                'auto',
                ...typeNames.map(() => 'auto'),
                'auto',
                'auto',
              ],
              body: [
                header,
                ...employees.map((e) => [
                  `${e.employeeName} (${e.employeeCode})`,
                  e.departmentName ?? '—',
                  ...e.balances.map((b) => `${num(b.remaining)} / ${num(b.allocated)}`),
                  num(e.totalAllocated),
                  num(e.totalRemaining),
                ]),
              ],
            },
            layout: {
              hLineColor: () => BRAND_BORDER,
              vLineColor: () => BRAND_BORDER,
            },
          },
        ];

  const docDefinition = {
    pageSize: 'A4',
    pageOrientation: 'landscape',
    pageMargins: [40, 40, 40, 40],
    defaultStyle: { font: 'Helvetica', fontSize: 9, color: '#14181F' },
    content: [
      {
        columns: [
          { image: ZERA_LOGO_BASE64, width: 110 },
          {
            width: '*',
            alignment: 'right',
            stack: [
              {
                text: "ALL EMPLOYEES' LEAVE",
                fontSize: 18,
                bold: true,
                color: BRAND_PRIMARY,
              },
              {
                text: `${year} — days remaining / total per leave type`,
                color: BRAND_TEXT_SECONDARY,
              },
            ],
          },
        ],
        margin: [0, 0, 0, 16],
      },
      ...body,
    ],
  };

  return new Promise((resolve, reject) => {
    const pdfDoc = printer.createPdfKitDocument(docDefinition);
    const chunks: Buffer[] = [];
    pdfDoc.on('data', (chunk: Buffer) => chunks.push(chunk));
    pdfDoc.on('end', () => resolve(Buffer.concat(chunks)));
    pdfDoc.on('error', reject);
    pdfDoc.end();
  });
}
