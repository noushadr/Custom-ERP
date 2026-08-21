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

/// A fixed, manually-maintained approximate PKR→USD rate for the dashboard's
/// secondary USD figures — not a live/fetched exchange rate. Update this
/// constant directly if it drifts too far from the real rate.
const pkrToUsdRate = 1 / 278;

/// Formats a PKR amount as its approximate USD equivalent for display below
/// the primary PKR figure, e.g. 250000 -> "≈ \$899".
String formatUsdApprox(double pkrAmount) =>
    '≈ \$${formatWholeAmount(pkrAmount * pkrToUsdRate)}';
