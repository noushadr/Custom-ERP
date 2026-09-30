import PdfPrinter from 'pdfmake';
import { Employee } from '../../employee/domain/entities/employee.entity';
import { PayrollLineItem } from '../domain/entities/payroll-line-item.entity';
import { PayrollRun } from '../domain/entities/payroll-run.entity';
import { toPayrollLineItemResponse } from './payroll.mapper';
import { ZERA_LOGO_BASE64 } from './zera-logo.base64';

const MONTH_NAMES = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const BRAND_PRIMARY = '#6C5DD3';
const BRAND_TEXT_SECONDARY = '#625F73';
const BRAND_BORDER = '#E3E1F0';
const BRAND_SUCCESS = '#16A34A';

function formatCurrency(amount: number): string {
  return `PKR ${amount.toLocaleString('en-PK', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

function formatDate(isoDate: string): string {
  return new Date(isoDate).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}

// pdfmake's PDFKit backend ships the 14 standard PDF fonts (no external
// .ttf files to manage) — Helvetica is one of them, referenced by name.
const printer = new PdfPrinter({
  Helvetica: {
    normal: 'Helvetica',
    bold: 'Helvetica-Bold',
    italics: 'Helvetica-Oblique',
    bolditalics: 'Helvetica-BoldOblique',
  },
});

/** Builds a branded payslip PDF for one employee line item of a Paid
 * payroll run. Only called after the caller (`PayrollService`) has already
 * validated the run is Paid and the item belongs to an employee (not a
 * freelancer, who has no payslip — see the class doc on
 * `PayrollLineItem`). */
export function generatePayslipPdf(
  run: PayrollRun,
  item: PayrollLineItem,
): Promise<Buffer> {
  const employee = item.employee as Employee;
  const line = toPayrollLineItemResponse(item);
  const periodLabel = `${MONTH_NAMES[run.month - 1]} ${run.year}`;

  const docDefinition: any = {
    pageSize: 'A4',
    pageMargins: [40, 40, 40, 40],
    defaultStyle: { font: 'Helvetica', fontSize: 10, color: '#14181F' },
    content: [
      {
        columns: [
          { image: ZERA_LOGO_BASE64, width: 110 },
          {
            width: '*',
            alignment: 'right',
            stack: [
              {
                text: 'PAYSLIP',
                fontSize: 18,
                bold: true,
                color: BRAND_PRIMARY,
              },
              {
                text: periodLabel,
                fontSize: 11,
                color: BRAND_TEXT_SECONDARY,
                margin: [0, 2, 0, 0],
              },
            ],
          },
        ],
      },
      {
        canvas: [
          {
            type: 'line',
            x1: 0,
            y1: 0,
            x2: 515,
            y2: 0,
            lineWidth: 1,
            lineColor: BRAND_BORDER,
          },
        ],
        margin: [0, 14, 0, 14],
      },
      {
        columns: [
          {
            width: '*',
            stack: [
              {
                text: `${employee.firstName} ${employee.lastName}`,
                fontSize: 13,
                bold: true,
              },
              {
                text: employee.designation ?? '—',
                color: BRAND_TEXT_SECONDARY,
                margin: [0, 2, 0, 0],
              },
              {
                text: employee.department?.name ?? '—',
                color: BRAND_TEXT_SECONDARY,
              },
            ],
          },
          {
            width: 220,
            alignment: 'right',
            stack: [
              {
                text: `Employee ID: ${employee.employeeCode}`,
                color: BRAND_TEXT_SECONDARY,
              },
              {
                text: `Joined: ${formatDate(employee.joiningDate)}`,
                color: BRAND_TEXT_SECONDARY,
                margin: [0, 2, 0, 0],
              },
            ],
          },
        ],
      },
      {
        margin: [0, 24, 0, 0],
        table: {
          widths: ['*', 'auto'],
          body: [
            [
              {
                text: 'Earnings & Deductions',
                bold: true,
                colSpan: 2,
                fillColor: '#F5F4FB',
                border: [false, false, false, false],
                margin: [4, 6, 0, 6],
              },
              {},
            ],
            ...(item.quantity != null && item.perUnitRate != null
              ? [
                  [
                    {
                      text: `Base Pay (${item.quantity} × ${formatCurrency(Number(item.perUnitRate))})`,
                      border: [false, false, false, true],
                      borderColor: [
                        BRAND_BORDER,
                        BRAND_BORDER,
                        BRAND_BORDER,
                        BRAND_BORDER,
                      ],
                      margin: [4, 6, 0, 6],
                    },
                    {
                      text: formatCurrency(line.baseSalary),
                      alignment: 'right',
                      border: [false, false, false, true],
                      borderColor: [
                        BRAND_BORDER,
                        BRAND_BORDER,
                        BRAND_BORDER,
                        BRAND_BORDER,
                      ],
                      margin: [0, 6, 4, 6],
                    },
                  ],
                ]
              : [
                  [
                    {
                      text: 'Base Salary',
                      border: [false, false, false, true],
                      borderColor: [
                        BRAND_BORDER,
                        BRAND_BORDER,
                        BRAND_BORDER,
                        BRAND_BORDER,
                      ],
                      margin: [4, 6, 0, 6],
                    },
                    {
                      text: formatCurrency(line.baseSalary),
                      alignment: 'right',
                      border: [false, false, false, true],
                      borderColor: [
                        BRAND_BORDER,
                        BRAND_BORDER,
                        BRAND_BORDER,
                        BRAND_BORDER,
                      ],
                      margin: [0, 6, 4, 6],
                    },
                  ],
                ]),
            [
              {
                text: 'Additions',
                border: [false, false, false, true],
                borderColor: [
                  BRAND_BORDER,
                  BRAND_BORDER,
                  BRAND_BORDER,
                  BRAND_BORDER,
                ],
                margin: [4, 6, 0, 6],
              },
              {
                text:
                  line.additions > 0
                    ? `+ ${formatCurrency(line.additions)}`
                    : '—',
                alignment: 'right',
                color: line.additions > 0 ? BRAND_SUCCESS : '#14181F',
                border: [false, false, false, true],
                borderColor: [
                  BRAND_BORDER,
                  BRAND_BORDER,
                  BRAND_BORDER,
                  BRAND_BORDER,
                ],
                margin: [0, 6, 4, 6],
              },
            ],
            [
              {
                text: 'Deductions',
                border: [false, false, false, true],
                borderColor: [
                  BRAND_BORDER,
                  BRAND_BORDER,
                  BRAND_BORDER,
                  BRAND_BORDER,
                ],
                margin: [4, 6, 0, 6],
              },
              {
                text:
                  line.deductions > 0
                    ? `- ${formatCurrency(line.deductions)}`
                    : '—',
                alignment: 'right',
                color: line.deductions > 0 ? '#DC2626' : '#14181F',
                border: [false, false, false, true],
                borderColor: [
                  BRAND_BORDER,
                  BRAND_BORDER,
                  BRAND_BORDER,
                  BRAND_BORDER,
                ],
                margin: [0, 6, 4, 6],
              },
            ],
            [
              {
                text: 'Net Pay',
                bold: true,
                fontSize: 12,
                fillColor: '#EDEBFC',
                border: [false, false, false, false],
                margin: [4, 8, 0, 8],
              },
              {
                text: formatCurrency(line.netPay),
                bold: true,
                fontSize: 12,
                color: BRAND_PRIMARY,
                alignment: 'right',
                fillColor: '#EDEBFC',
                border: [false, false, false, false],
                margin: [0, 8, 4, 8],
              },
            ],
          ],
        },
      },
      ...(item.notes
        ? [
            {
              text: `Notes: ${item.notes}`,
              italics: true,
              color: BRAND_TEXT_SECONDARY,
              margin: [0, 12, 0, 0] as [number, number, number, number],
            },
          ]
        : []),
      {
        margin: [0, 40, 0, 0],
        text: `This is a system-generated payslip from Zera Creative's internal ERP and does not require a signature. Generated on ${new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' })}.`,
        fontSize: 8,
        color: BRAND_TEXT_SECONDARY,
        alignment: 'center',
      },
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
