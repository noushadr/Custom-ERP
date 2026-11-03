import 'dart:typed_data';

/// A file the user chose to upload with an article.
class KnowledgeBaseUploadFile {
  const KnowledgeBaseUploadFile({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}
