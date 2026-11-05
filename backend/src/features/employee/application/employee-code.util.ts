/** Employee IDs look like ZC-073: the company prefix and a number with at
 * least three digits. */
export const EMPLOYEE_CODE_PATTERN = /^ZC-\d{3,}$/i;

/** After this many days an employee's ID is fixed — HR/Admin can correct it
 * only shortly after adding them. */
export const EMPLOYEE_CODE_EDIT_WINDOW_DAYS = 30;

export function normalizeEmployeeCode(code: string): string {
  return code.trim().toUpperCase();
}

/** The next ID in the sequence: one above the highest number ever used (by
 * anyone, current or past, whatever width it was written in), never a gap
 * filled and never a reuse. Codes that don't follow the pattern are ignored. */
export function nextEmployeeCode(existingCodes: string[]): string {
  let highest = 0;
  for (const code of existingCodes) {
    const match = /^ZC-(\d+)$/i.exec(code.trim());
    if (match) highest = Math.max(highest, Number(match[1]));
  }
  return `ZC-${String(highest + 1).padStart(3, '0')}`;
}

/** True once the 30-day window since the employee was added has passed. */
export function isEmployeeCodeLocked(
  createdAt: Date | undefined,
  now: Date = new Date(),
): boolean {
  if (!createdAt) return false;
  const ageMs = now.getTime() - createdAt.getTime();
  return ageMs > EMPLOYEE_CODE_EDIT_WINDOW_DAYS * 24 * 60 * 60 * 1000;
}
