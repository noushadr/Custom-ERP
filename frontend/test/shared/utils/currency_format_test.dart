import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/shared/utils/currency_format.dart';

void main() {
  group('formatUsdApprox', () {
    test('converts a PKR amount to an approximate USD figure', () {
      expect(formatUsdApprox(250000), '≈ \$899');
    });

    test('formats a small amount without a decimal', () {
      expect(formatUsdApprox(8333.33), '≈ \$29');
    });

    test('formats zero as \$0', () {
      expect(formatUsdApprox(0), '≈ \$0');
    });
  });
}
