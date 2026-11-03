import PdfPrinter from 'pdfmake';
import { ZERA_LOGO_BASE64 } from '../../payroll/application/zera-logo.base64';
import { EmployeeAttendanceResponse } from './attendance-response.interface';
import { formatMinutes } from './attendance.calculator';

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
const WARNING = '#B45309';
const DANGER = '#B91C1C';

const printer = new PdfPrinter({
  Helvetica: {
    normal: 'Helvetica',
    bold: 'Helvetica-Bold',
    italics: 'Helvetica-Oblique',
    bolditalics: 'Helvetica-BoldOblique',
  },
});

const STATUS_LABEL: Record<string, string> = {
  present: 'Present',
  late: 'Late',
  incomplete: 'No check-out',
  absent: 'Absent',
  leave: 'Leave',
  holiday: 'Holiday',
  weekend: 'Weekend',
  pending: '',
  upcoming: '',
};

const dash = (value: string | null): string => value ?? '';
const minutes = (value: number): string =>
  value > 0 ? formatMinutes(value) : '';

function formatDate(iso: string): string {
  const [y, m, d] = iso.split('-');
  return `${d}/${m}/${y}`;
}

/** One section per employee in the same columns as the machine software's
 * own monthly report (date, clock in/out, late, early, work time). */
export function generateAttendancePdf(
  employees: EmployeeAttendanceResponse[],
  month: number,
  year: number,
): Promise<Buffer> {
  const title = `${MONTH_NAMES[month - 1]} ${year}`;
  const content: unknown[] = [
    {
      columns: [
        { image: ZERA_LOGO_BASE64, width: 110 },
        {
          width: '*',
          alignment: 'right',
          stack: [
            {
              text: 'ATTENDANCE REPORT',
              fontSize: 18,
              bold: true,
              color: BRAND_PRIMARY,
            },
            { text: title, color: BRAND_TEXT_SECONDARY },
          ],
        },
      ],
      margin: [0, 0, 0, 12],
    },
  ];

  employees.forEach((employee, index) => {
    const s = employee.summary;
    const heading = {
      text: `${employee.employeeName} (${employee.employeeCode})`,
      bold: true,
      fontSize: 12,
      margin: [0, 8, 0, 2],
      ...(index > 0 ? { pageBreak: 'before' } : {}),
    };
    content.push(heading);

    if (!employee.linked) {
      content.push({
        text: 'Not linked to the attendance machine yet.',
        color: BRAND_TEXT_SECONDARY,
      });
      return;
    }

    content.push({
      text:
        `Present ${s.present}   Late ${s.late}   Absent ${s.absent}   ` +
        `Leave ${s.leave}   Late time ${formatMinutes(s.lateMinutes)}   ` +
        `Worked ${formatMinutes(s.workMinutes)}`,
      color: BRAND_TEXT_SECONDARY,
      margin: [0, 0, 0, 6],
    });
    content.push({
      table: {
        headerRows: 1,
        widths: ['auto', 'auto', 'auto', 'auto', 'auto', 'auto', 'auto', '*'],
        body: [
          ['Date', 'Day', 'Clock In', 'Clock Out', 'Late', 'Early', 'Work', 'Status'].map(
            (text) => ({ text, bold: true, color: BRAND_PRIMARY }),
          ),
          ...employee.days.map((d) => {
            const color =
              d.status === 'absent'
                ? DANGER
                : d.status === 'late' || d.status === 'incomplete'
                  ? WARNING
                  : undefined;
            return [
              formatDate(d.date),
              d.weekday,
              dash(d.clockIn),
              dash(d.clockOut),
              minutes(d.lateMinutes),
              minutes(d.earlyMinutes),
              minutes(d.workMinutes),
              { text: STATUS_LABEL[d.status] ?? '', color },
            ];
          }),
        ],
      },
      layout: {
        hLineColor: () => BRAND_BORDER,
        vLineColor: () => BRAND_BORDER,
      },
      fontSize: 8,
    });
  });

  const docDefinition = {
    pageSize: 'A4',
    pageMargins: [40, 36, 40, 36],
    defaultStyle: { font: 'Helvetica', fontSize: 9, color: '#14181F' },
    content,
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
