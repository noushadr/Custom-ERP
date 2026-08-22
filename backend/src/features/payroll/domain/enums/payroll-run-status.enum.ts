/** Draft: line items are still editable. Finalized: locked, awaiting
 * payment. Paid: the permanent historical record — never edited again. */
export enum PayrollRunStatus {
  DRAFT = 'draft',
  FINALIZED = 'finalized',
  PAID = 'paid',
}
