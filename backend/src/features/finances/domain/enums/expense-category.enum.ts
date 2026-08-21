/** PAYROLL is deliberately not a category here — payroll cost is reported
 * live from EmployeesService.getPayrollSummary(), not logged as a manual
 * expense, to avoid two systems disagreeing about the same figure. */
export enum ExpenseCategory {
  RENT_UTILITIES = 'rent_utilities',
  SOFTWARE_TOOLS = 'software_tools',
  MARKETING = 'marketing',
  VENDOR_PAYMENT = 'vendor_payment',
  TAXES = 'taxes',
  COMMISSIONS = 'commissions',
  OTHER = 'other',
}
