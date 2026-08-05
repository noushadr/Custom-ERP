import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/shared/utils/date_format.dart';

void main() {
  group('formatDisplayDate', () {
    test('formats a single-digit day with zero padding', () {
      expect(formatDisplayDate('2026-05-03'), 'May 03, 2026');
    });

    test('formats a double-digit day without extra padding', () {
      expect(formatDisplayDate('2016-06-02'), 'June 02, 2016');
    });

    test('formats December correctly', () {
      expect(formatDisplayDate('1999-12-25'), 'December 25, 1999');
    });
  });
}
