/// Display title for a review cycle: [period] 1 is the June cycle, 2 the
/// December cycle (e.g. "June 2026 Review").
String performanceReviewTitle(int year, int period) =>
    '${period == 1 ? 'June' : 'December'} $year Review';
