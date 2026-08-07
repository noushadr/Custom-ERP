import '../../../../core/config/app_config.dart';
import '../../domain/entities/employee_document.dart';

class EmployeeDocumentModel extends EmployeeDocument {
  const EmployeeDocumentModel({
    required super.id,
    required super.documentType,
    required super.fileName,
    required super.fileSize,
    required super.url,
    required super.uploadedAt,
  });

  factory EmployeeDocumentModel.fromJson(Map<String, dynamic> json) =>
      EmployeeDocumentModel(
        id: json['id'] as String,
        documentType: documentTypeFromJson(json['documentType'] as String),
        fileName: json['fileName'] as String,
        fileSize: json['fileSize'] as int,
        url: _resolveUrl(json['url'] as String),
        uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      );

  /// Mirrors [EmployeeModel]'s photo URL resolution — the backend returns
  /// paths relative to itself so responses stay portable across environments.
  static String _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '${AppConfig.apiBaseUrl}$url';
  }
}
