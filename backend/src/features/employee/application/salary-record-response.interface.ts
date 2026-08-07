export interface SalaryRecordResponse {
  id: string;
  amount: string;
  effectiveDate: string;
  note: string | null;
  createdAt: Date;
}
