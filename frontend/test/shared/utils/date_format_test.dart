import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/shared/utils/date_format.dart';

void main() {
  group('formatDisplayDate', () {
    test('formats a single-digit day with zero padding', () {
      expect(formatDisplayDate('2026-05-03'), 'May 03, 2026');
    });

    test('formats a double-digit day without extra padding', () {
      expect(formatDisplayDate('2016-06-02'), 'Jun 02, 2016');
    });

    test('formats December correctly', () {
      expect(formatDisplayDate('1999-12-25'), 'Dec 25, 1999');
    });
  });

  group('formatDisplayDateTime', () {
    test('shifts a UTC timestamp to Pakistan Standard Time (UTC+5)', () {
      final utc = DateTime.utc(2026, 8, 14, 10, 30);
      expect(formatDisplayDateTime(utc), 'Aug 14, 2026, 3:30 PM');
    });

    test(
      'rolls over to the next calendar day when the +5h shift crosses midnight',
      () {
        final utc = DateTime.utc(2026, 8, 13, 20, 15);
        expect(formatDisplayDateTime(utc), 'Aug 14, 2026, 1:15 AM');
      },
    );

    test('formats midnight as 12 AM', () {
      final utc = DateTime.utc(2026, 1, 1, 19, 0);
      expect(formatDisplayDateTime(utc), 'Jan 02, 2026, 12:00 AM');
    });
  });
}
