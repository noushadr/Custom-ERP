/// Formats a numeric amount with thousands separators and 2 decimal places,
/// e.g. 50000 -> "50,000.00".
String formatAmount(double amount) {
  final fixed = amount.toStringAsFixed(2);
  final parts = fixed.split('.');
  final negative = parts[0].startsWith('-');
  final digits = negative ? parts[0].substring(1) : parts[0];

  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }

  return '${negative ? '-' : ''}$buffer.${parts[1]}';
}

/// Like [formatAmount] but without cents, e.g. 50000.49 -> "50,000" — for
/// headline figures (dashboard totals) where exact cents aren't meaningful.
String formatWholeAmount(double amount) => formatAmount(amount).split('.').first;
