import {
  isEmployeeCodeLocked,
  nextEmployeeCode,
  normalizeEmployeeCode,
} from './employee-code.util';

describe('nextEmployeeCode', () => {
  it('continues from the highest number ever used, with three digits', () => {
    expect(nextEmployeeCode(['ZC-001', 'ZC-071', 'ZC-050'])).toBe('ZC-072');
  });

  it('reads old five-digit codes by their number, not their width', () => {
    expect(nextEmployeeCode(['ZC-071', 'ZC-00077'])).toBe('ZC-078');
  });

  it('starts at 001 with nobody yet, and ignores codes outside the pattern', () => {
    expect(nextEmployeeCode([])).toBe('ZC-001');
    expect(nextEmployeeCode(['TEST-001', 'abc'])).toBe('ZC-001');
  });

  it('grows past three digits naturally', () => {
    expect(nextEmployeeCode(['ZC-999'])).toBe('ZC-1000');
  });
});

describe('normalizeEmployeeCode', () => {
  it('trims and upper-cases', () => {
    expect(normalizeEmployeeCode(' zc-073 ')).toBe('ZC-073');
  });
});

describe('isEmployeeCodeLocked', () => {
  const now = new Date('2026-11-05T00:00:00Z');
  it('is open for 30 days and locked after', () => {
    expect(isEmployeeCodeLocked(new Date('2026-10-10T00:00:00Z'), now)).toBe(
      false,
    );
    expect(isEmployeeCodeLocked(new Date('2026-10-05T00:00:00Z'), now)).toBe(
      true,
    );
  });
});
