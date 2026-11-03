import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/knowledge_base_upload_file.dart';
import '../../../shared/utils/file_download/file_download.dart';

/// A file the user chose to upload.
typedef PickedKnowledgeBaseFile = KnowledgeBaseUploadFile;

/// One SOP can carry up to this many files (kept in step with the backend's
/// `KNOWLEDGE_BASE_MAX_FILES`).
const knowledgeBaseMaxFiles = 3;

/// The extensions the backend accepts (kept in step with
/// `knowledge-base-upload.config.ts`) — the picker only offers these.
const knowledgeBaseAllowedExtensions = [
  'pdf',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'ppt',
  'pptx',
  'csv',
  'txt',
  'png',
  'jpg',
  'jpeg',
  'webp',
];

/// Asks the user to choose one or more files (empty when they cancel). A
/// provider so widget tests can supply files without a real browser file
/// dialog.
final knowledgeBaseFilePickerProvider =
    Provider<Future<List<PickedKnowledgeBaseFile>> Function()>((ref) {
      return () async {
        final result = await FilePicker.platform.pickFiles(
          withData: true,
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: knowledgeBaseAllowedExtensions,
        );
        if (result == null) return const [];
        return [
          for (final picked in result.files)
            if (picked.bytes != null)
              PickedKnowledgeBaseFile(
                fileName: picked.name,
                bytes: picked.bytes!,
              ),
        ];
      };
    });

/// What the viewer can do with a fetched file. A provider (like the picker)
/// so tests can observe the calls — the real web implementations throw on a
/// non-web platform.
class KnowledgeBaseFileActions {
  const KnowledgeBaseFileActions({required this.download, required this.open});

  final void Function(Uint8List bytes, String fileName, String mimeType)
  download;

  /// Opens the file in a new tab; returns false if the browser blocked the
  /// pop-up (the caller then falls back to a download).
  final bool Function(Uint8List bytes, String mimeType) open;
}

final knowledgeBaseFileActionsProvider = Provider<KnowledgeBaseFileActions>(
  (ref) => KnowledgeBaseFileActions(
    download: (bytes, fileName, mimeType) =>
        downloadBytes(bytes, fileName, mimeType: mimeType),
    open: (bytes, mimeType) => openBytesInNewTab(bytes, mimeType: mimeType),
  ),
);

/// Types the browser can show itself in a new tab — PDFs, images and plain
/// text. Everything else (Word/Excel/PowerPoint...) is download-only.
bool canOpenInBrowser(String? mimeType) {
  if (mimeType == null) return false;
  return mimeType == 'application/pdf' ||
      mimeType == 'text/plain' ||
      mimeType.startsWith('image/');
}
