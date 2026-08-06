class EmployeeDocument {
  const EmployeeDocument({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.url,
    required this.uploadedAt,
  });

  final String id;
  final String fileName;
  final int fileSize;
  final String url;
  final DateTime uploadedAt;
}
