import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/employee_document.dart';
import '../../domain/exceptions/employee_exception.dart';

const _typedSlots = [
  (type: DocumentType.contract, label: 'Contract'),
  (type: DocumentType.resume, label: 'Resume'),
  (type: DocumentType.cnic, label: 'CNIC / National ID'),
];

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
  DocumentType? _uploadingType;
  String? _deletingDocumentId;

  bool get _isSelf => widget.employeeId == null;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickAndUpload(DocumentType documentType) async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    final picked = result?.files.single;
    if (picked?.bytes == null) return;

    setState(() => _uploadingType = documentType);
    try {
      final repository = ref.read(employeeRepositoryProvider);
      if (_isSelf) {
        await repository.uploadMyDocument(
          picked!.bytes!,
          picked.name,
          documentType: documentType,
        );
        ref.invalidate(myDocumentsProvider);
        ref.invalidate(myAuditLogProvider);
      } else {
        await repository.uploadDocument(
          widget.employeeId!,
          picked!.bytes!,
          picked.name,
          documentType: documentType,
        );
        ref.invalidate(employeeDocumentsProvider(widget.employeeId!));
        ref.invalidate(employeeAuditLogProvider(widget.employeeId!));
      }
    } on EmployeeException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _uploadingType = null);
    }
  }

  Future<void> _delete(EmployeeDocument document) async {
    setState(() => _deletingDocumentId = document.id);
    try {
      final repository = ref.read(employeeRepositoryProvider);
      if (_isSelf) {
        await repository.deleteMyDocument(document.id);
        ref.invalidate(myDocumentsProvider);
        ref.invalidate(myAuditLogProvider);
      } else {
        await repository.deleteDocument(widget.employeeId!, document.id);
        ref.invalidate(employeeDocumentsProvider(widget.employeeId!));
        ref.invalidate(employeeAuditLogProvider(widget.employeeId!));
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
      child: documentsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load documents.'),
        data: (documents) {
          final byType = <DocumentType, EmployeeDocument>{};
          final other = <EmployeeDocument>[];
          for (final document in documents) {
            if (document.documentType == DocumentType.other) {
              other.add(document);
            } else {
              byType[document.documentType] = document;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final slot in _typedSlots) ...[
                _DocumentSlot(
                  label: slot.label,
                  document: byType[slot.type],
                  isUploading: _uploadingType == slot.type,
                  isDeleting:
                      byType[slot.type] != null &&
                      _deletingDocumentId == byType[slot.type]!.id,
                  onOpen: byType[slot.type] == null
                      ? null
                      : () => _open(byType[slot.type]!),
                  onUpload: () => _pickAndUpload(slot.type),
                  onDelete: byType[slot.type] == null
                      ? null
                      : () => _delete(byType[slot.type]!),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Other documents',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              if (other.isEmpty)
                Text(
                  'No other files attached.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                for (final document in other)
                  _DocumentTile(
                    document: document,
                    isDeleting: _deletingDocumentId == document.id,
                    onOpen: () => _open(document),
                    onDelete: () => _delete(document),
                  ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _uploadingType != null
                      ? null
                      : () => _pickAndUpload(DocumentType.other),
                  icon: _uploadingType == DocumentType.other
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.attach_file, size: 18),
                  label: Text(
                    _uploadingType == DocumentType.other
                        ? 'Uploading…'
                        : 'Add file',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class _DocumentSlot extends StatelessWidget {
  const _DocumentSlot({
    required this.label,
    required this.document,
    required this.isUploading,
    required this.isDeleting,
    required this.onUpload,
    this.onOpen,
    this.onDelete,
  });

  final String label;
  final EmployeeDocument? document;
  final bool isUploading;
  final bool isDeleting;
  final VoidCallback onUpload;
  final VoidCallback? onOpen;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.canvasBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 2),
                if (document == null)
                  Text(
                    'Not uploaded',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  InkWell(
                    onTap: onOpen,
                    child: Text(
                      '${document!.fileName} · ${_formatFileSize(document!.fileSize)}',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isUploading || isDeleting)
            const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (document == null)
            TextButton(onPressed: onUpload, child: const Text('Upload'))
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: onUpload,
                  child: const Text('Replace'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Remove',
                  onPressed: onDelete,
                ),
              ],
            ),
        ],
      ),
    );
  }
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
