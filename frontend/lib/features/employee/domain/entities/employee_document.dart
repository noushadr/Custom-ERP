enum DocumentType { contract, resume, cnic, other }

DocumentType documentTypeFromJson(String value) => switch (value) {
  'contract' => DocumentType.contract,
  'resume' => DocumentType.resume,
  'cnic' => DocumentType.cnic,
  _ => DocumentType.other,
};

String documentTypeToJson(DocumentType type) => switch (type) {
  DocumentType.contract => 'contract',
  DocumentType.resume => 'resume',
  DocumentType.cnic => 'cnic',
  DocumentType.other => 'other',
};

class EmployeeDocument {
  const EmployeeDocument({
    required this.id,
    required this.documentType,
    required this.fileName,
    required this.fileSize,
    required this.url,
    required this.uploadedAt,
  });

  final String id;
  final DocumentType documentType;
  final String fileName;
  final int fileSize;
  final String url;
  final DateTime uploadedAt;
}
