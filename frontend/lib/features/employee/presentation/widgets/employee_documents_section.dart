import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/employee_document.dart';
import '../../domain/exceptions/employee_exception.dart';

/// Lets the viewer attach files to an employee's record and lists what's
/// already attached. Pass null for [employeeId] to manage the current
/// user's own documents; pass an id (requires `employees.manage`) to manage
/// another employee's.
class EmployeeDocumentsSection extends ConsumerStatefulWidget {
  const EmployeeDocumentsSection({super.key, this.employeeId});

  final String? employeeId;

  @override
  ConsumerState<EmployeeDocumentsSection> createState() =>
      _EmployeeDocumentsSectionState();
}

class _EmployeeDocumentsSectionState
    extends ConsumerState<EmployeeDocumentsSection> {
  bool _isUploading = false;
  String? _deletingDocumentId;

  bool get _isSelf => widget.employeeId == null;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    final picked = result?.files.single;
    if (picked?.bytes == null) return;

    setState(() => _isUploading = true);
    try {
      final repository = ref.read(employeeRepositoryProvider);
      if (_isSelf) {
        await repository.uploadMyDocument(picked!.bytes!, picked.name);
        ref.invalidate(myDocumentsProvider);
      } else {
        await repository.uploadDocument(
          widget.employeeId!,
          picked!.bytes!,
          picked.name,
        );
        ref.invalidate(employeeDocumentsProvider(widget.employeeId!));
      }
    } on EmployeeException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _delete(EmployeeDocument document) async {
    setState(() => _deletingDocumentId = document.id);
    try {
      final repository = ref.read(employeeRepositoryProvider);
      if (_isSelf) {
        await repository.deleteMyDocument(document.id);
        ref.invalidate(myDocumentsProvider);
      } else {
        await repository.deleteDocument(widget.employeeId!, document.id);
        ref.invalidate(employeeDocumentsProvider(widget.employeeId!));
      }
    } on EmployeeException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _deletingDocumentId = null);
    }
  }

  Future<void> _open(EmployeeDocument document) async {
    final uri = Uri.parse(document.url);
    final opened = await launchUrl(uri, webOnlyWindowName: '_blank');
    if (!opened) _showError('Could not open ${document.fileName}');
  }

  @override
  Widget build(BuildContext context) {
    final documentsAsync = _isSelf
        ? ref.watch(myDocumentsProvider)
        : ref.watch(employeeDocumentsProvider(widget.employeeId!));

    return FormSection(
      title: 'Documents',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          documentsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            ),
            error: (_, _) => const Text('Could not load documents.'),
            data: (documents) => documents.isEmpty
                ? Text(
                    'No files attached yet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                : Column(
                    children: [
                      for (final document in documents)
                        _DocumentTile(
                          document: document,
                          isDeleting: _deletingDocumentId == document.id,
                          onOpen: () => _open(document),
                          onDelete: () => _delete(document),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _isUploading ? null : _pickAndUpload,
              icon: _isUploading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file, size: 18),
              label: Text(_isUploading ? 'Uploading…' : 'Add file'),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.document,
    required this.isDeleting,
    required this.onOpen,
    required this.onDelete,
  });

  final EmployeeDocument document;
  final bool isDeleting;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Text(
                document.fileName,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatFileSize(document.fileSize),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          isDeleting
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Remove',
                  onPressed: onDelete,
                ),
        ],
      ),
    );
  }
}
