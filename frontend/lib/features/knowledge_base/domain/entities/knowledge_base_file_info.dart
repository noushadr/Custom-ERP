/// One uploaded file of a file article (or of a past version of one).
class KnowledgeBaseFileInfo {
  const KnowledgeBaseFileInfo({
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
  });

  final String fileName;
  final String mimeType;
  final int sizeBytes;

  factory KnowledgeBaseFileInfo.fromJson(Map<String, dynamic> json) =>
      KnowledgeBaseFileInfo(
        fileName: json['fileName'] as String,
        mimeType: json['fileMimeType'] as String,
        sizeBytes: json['fileSizeBytes'] as int,
      );
}

/// Parses the `files` list of an API response (absent for a written article).
List<KnowledgeBaseFileInfo> knowledgeBaseFilesFromJson(dynamic json) =>
    (json as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(KnowledgeBaseFileInfo.fromJson)
        .toList();
