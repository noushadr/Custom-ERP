class UpcomingBirthday {
  const UpcomingBirthday({
    required this.employeeId,
    required this.fullName,
    this.profilePhotoUrl,
    required this.dateOfBirth,
    required this.daysUntil,
  });

  final String employeeId;
  final String fullName;
  final String? profilePhotoUrl;
  final String dateOfBirth;

  /// 0 means today; negative means the birthday already happened this many
  /// days ago; positive means it's this many days away.
  final int daysUntil;
}
