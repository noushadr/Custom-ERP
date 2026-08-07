class EducationRecord {
  const EducationRecord({
    required this.id,
    required this.degree,
    required this.institution,
    required this.yearCompleted,
    required this.createdAt,
  });

  final String id;
  final String degree;
  final String institution;
  final int yearCompleted;
  final DateTime createdAt;
}
