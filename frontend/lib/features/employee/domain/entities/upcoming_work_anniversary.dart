class UpcomingWorkAnniversary {
  const UpcomingWorkAnniversary({
    required this.employeeId,
    required this.fullName,
    this.profilePhotoUrl,
    required this.joiningDate,
    required this.daysUntil,
    required this.yearsOfService,
  });

  final String employeeId;
  final String fullName;
  final String? profilePhotoUrl;
  final String joiningDate;

  /// 0 means today; negative means the anniversary already happened this
  /// many days ago; positive means it's this many days away.
  final int daysUntil;

  /// Full years of service being marked, e.g. 3 for a 3rd anniversary.
  final int yearsOfService;
}
