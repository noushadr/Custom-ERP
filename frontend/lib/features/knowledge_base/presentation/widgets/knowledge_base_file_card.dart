import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/format_file_size.dart';
import '../../application/knowledge_base_file_support.dart';
import '../../domain/exceptions/knowledge_base_exception.dart';

/// The body of an uploaded-file article (or a past version of one): which
/// file it is, with Open (when the browser can display it) and Download.
/// [load] fetches the bytes through the authenticated API — uploaded files
/// are never reachable by URL alone.
class KnowledgeBaseFileCard extends ConsumerStatefulWidget {
  const KnowledgeBaseFileCard({
    super.key,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.load,
  });

  final String fileName;
  final String? mimeType;
  final int? sizeBytes;
  final Future<Uint8List> Function() load;

  @override
  ConsumerState<KnowledgeBaseFileCard> createState() =>
      _KnowledgeBaseFileCardState();
}

class _KnowledgeBaseFileCardState extends ConsumerState<KnowledgeBaseFileCard> {
  bool _busy = false;

  String get _mimeType => widget.mimeType ?? 'application/octet-stream';

  Future<void> _run({required bool open}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await widget.load();
      final actions = ref.read(knowledgeBaseFileActionsProvider);
      // A blocked pop-up falls back to a normal download.
      if (!open || !actions.open(bytes, _mimeType)) {
        actions.download(bytes, widget.fileName, _mimeType);
      }
    } on KnowledgeBaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canOpen = canOpenInBrowser(widget.mimeType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(_iconFor(widget.mimeType), size: 36, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.fileName,
                  style: textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.sizeBytes != null)
                  Text(
                    formatFileSize(widget.sizeBytes!),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (_busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            if (canOpen)
              OutlinedButton.icon(
                onPressed: () => _run(open: true),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Open'),
              ),
            if (canOpen) const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _run(open: false),
              icon: const Icon(Icons.download_outlined, size: 16),
              label: const Text('Download'),
            ),
          ],
        ],
      ),
    );
  }
}

IconData _iconFor(String? mimeType) {
  if (mimeType == null) return Icons.insert_drive_file_outlined;
  if (mimeType == 'application/pdf') return Icons.picture_as_pdf_outlined;
  if (mimeType.startsWith('image/')) return Icons.image_outlined;
  if (mimeType.contains('word')) return Icons.description_outlined;
  if (mimeType.contains('sheet') ||
      mimeType.contains('excel') ||
      mimeType == 'text/csv') {
    return Icons.table_chart_outlined;
  }
  if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
    return Icons.slideshow_outlined;
  }
  return Icons.insert_drive_file_outlined;
}
