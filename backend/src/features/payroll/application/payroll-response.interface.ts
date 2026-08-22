export interface PayrollLineItemResponseDto {
  id: string;
  employeeId: string;
  employeeName: string;
  employeePhotoUrl: string | null;
  baseSalary: number;
  bonuses: number;
  allowances: number;
  overtime: number;
  deductions: number;
  advances: number;
  tax: number;
  /** Computed: baseSalary + bonuses + allowances + overtime - deductions
   * - advances - tax. Never stored. */
  netPay: number;
  notes: string | null;
}

export interface PayrollRunSummaryDto {
  id: string;
  month: number;
  year: number;
  status: string;
  employeeCount: number;
  /** Sum of every line item's netPay. */
  totalNetPay: number;
  generatedByName: string;
  finalizedByName: string | null;
  finalizedAt: string | null;
  paidByName: string | null;
  paidAt: string | null;
  createdAt: string;
}

export interface PayrollRunDetailDto extends PayrollRunSummaryDto {
  lineItems: PayrollLineItemResponseDto[];
}
