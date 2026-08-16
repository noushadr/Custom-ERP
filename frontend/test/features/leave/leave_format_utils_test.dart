import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/leave/presentation/utils/leave_format_utils.dart';

void main() {
  group('countWorkingDays', () {
    test('counts a single weekday as one day', () {
      // Wednesday 2026-03-04.
      final day = DateTime(2026, 3, 4);
      expect(countWorkingDays(day, day, {}), 1);
    });

    test('excludes Saturday/Sunday from a range spanning a weekend', () {
      // Friday 2026-03-06 through Monday 2026-03-09 = Fri + Mon = 2 days.
      final start = DateTime(2026, 3, 6);
      final end = DateTime(2026, 3, 9);
      expect(countWorkingDays(start, end, {}), 2);
    });

    test('counts a full Mon-Fri work week as five days', () {
      final start = DateTime(2026, 3, 2);
      final end = DateTime(2026, 3, 6);
      expect(countWorkingDays(start, end, {}), 5);
    });

    test('excludes configured holiday dates', () {
      // Mon-Fri 2026-03-02..06, with Wednesday the 4th a public holiday.
      final start = DateTime(2026, 3, 2);
      final end = DateTime(2026, 3, 6);
      expect(countWorkingDays(start, end, {'2026-03-04'}), 4);
    });

    test('returns zero for a weekend-only range', () {
      final start = DateTime(2026, 3, 7); // Saturday
      final end = DateTime(2026, 3, 8); // Sunday
      expect(countWorkingDays(start, end, {}), 0);
    });
  });

  group('isoDate', () {
    test('pads month and day to two digits', () {
      expect(isoDate(DateTime(2026, 3, 4)), '2026-03-04');
    });
  });
}
