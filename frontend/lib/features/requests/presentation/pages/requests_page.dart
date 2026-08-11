import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../employee/presentation/widgets/employee_status_badges.dart';
import '../../application/request_providers.dart';
import '../../domain/entities/employee_request.dart';
import '../../domain/exceptions/request_exception.dart';

/// Consolidates everything about employee requests in one place: the
/// viewer's own submitted requests (general, item, and profile-change), any
/// requests awaiting their approval as a reporting manager, and — for
/// HR/Admin — requests awaiting the final HR/Admin decision.
class RequestsPage extends ConsumerWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final authUser = authState is AuthAuthenticated ? authState.user : null;
    final canSeeHrApprovals = authUser?.hasPermission('users.manage') ?? false;
    // Super Admin's own edits apply immediately (see EditMyProfilePage) and
    // they have no need to request items for themselves, so neither "My
    // Requests" nor its submission buttons apply to them — they only use
    // this page to decide on requests from everyone else.
    final isSuperAdmin = authUser?.role == 'Super Admin';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isSuperAdmin) ...[
                  const _MyRequestsSection(),
                  const SizedBox(height: 16),
                ],
                const _PendingMyApprovalSection(),
                if (canSeeHrApprovals) ...[
                  const SizedBox(height: 16),
                  const _PendingHrApprovalSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyRequestsSection extends ConsumerWidget {
  const _MyRequestsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myRequestsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'My Requests',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const _RequestItemDialog(),
                  ),
                  icon: const Icon(Icons.inventory_2_outlined, size: 16),
                  label: const Text('Request an item'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const _SubmitRequestDialog(),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New request'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            requestsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              ),
              error: (_, _) => const Text('Could not load your requests.'),
              data: (requests) {
                if (requests.isEmpty) {
                  return Text(
                    "You haven't submitted any requests yet.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < requests.length; i++) ...[
                      _MyRequestRow(request: requests[i]),
                      if (i < requests.length - 1)
                        const Divider(
                          height: 20,
                          color: AppColors.borderSubtle,
                        ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MyRequestRow extends StatelessWidget {
  const _MyRequestRow({required this.request});

  final EmployeeRequest request;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                request.subject,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            _RequestStatusBadge(status: request.status),
          ],
        ),
        const SizedBox(height: 4),
        Text(request.description, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          formatDisplayDateTime(request.createdAt),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        if (request.rejectionReason != null) ...[
          const SizedBox(height: 4),
          Text(
            'Reason: ${request.rejectionReason}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _RequestStatusBadge extends StatelessWidget {
  const _RequestStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'submitted' => ('Submitted', AppColors.warning),
      'manager_approved' => ('Manager Approved', AppColors.primary),
      'completed' => ('Completed', AppColors.success),
      'rejected' => ('Rejected', AppColors.error),
      _ => (status, AppColors.textSecondary),
    };
    return StatusBadge(label: label, color: color);
  }
}

class _SubmitRequestDialog extends ConsumerStatefulWidget {
  const _SubmitRequestDialog();

  @override
  ConsumerState<_SubmitRequestDialog> createState() =>
      _SubmitRequestDialogState();
}

class _SubmitRequestDialogState extends ConsumerState<_SubmitRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _subjectController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(requestRepositoryProvider)
          .submit(
            subject: _subjectController.text,
            description: _descriptionController.text,
            type: _typeController.text.trim().isEmpty
                ? null
                : _typeController.text.trim(),
          );
      ref.invalidate(myRequestsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on RequestException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New request'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                  hintText: 'e.g. Equipment, Document, Access',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}

class _RequestItemDialog extends ConsumerStatefulWidget {
  const _RequestItemDialog();

  @override
  ConsumerState<_RequestItemDialog> createState() =>
      _RequestItemDialogState();
}

class _RequestItemDialogState extends ConsumerState<_RequestItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _purposeController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _itemController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(requestRepositoryProvider)
          .submitItemRequest(
            itemName: _itemController.text.trim(),
            purpose: _purposeController.text.trim(),
          );
      ref.invalidate(myRequestsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on RequestException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request an item'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _itemController,
                decoration: const InputDecoration(
                  labelText: 'Item needed',
                  hintText: 'e.g. Stationery, a new keyboard',
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                    ? 'Required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _purposeController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Purpose'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                    ? 'Required'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}

/// Requests submitted by one of this viewer's direct reports, awaiting their
/// approval as reporting manager. Empty for anyone without direct reports.
class _PendingMyApprovalSection extends ConsumerWidget {
  const _PendingMyApprovalSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingManagerApprovalRequestsProvider);

    return FormSection(
      title: 'Requests Awaiting My Approval',
      child: requestsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load pending requests.'),
        data: (requests) {
          if (requests.isEmpty) {
            return Text(
              'Nothing is waiting for your approval.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < requests.length; i++) ...[
                _PendingManagerRequestRow(request: requests[i]),
                if (i < requests.length - 1)
                  const Divider(height: 20, color: AppColors.borderSubtle),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PendingManagerRequestRow extends ConsumerStatefulWidget {
  const _PendingManagerRequestRow({required this.request});

  final EmployeeRequest request;

  @override
  ConsumerState<_PendingManagerRequestRow> createState() =>
      _PendingManagerRequestRowState();
}

class _PendingManagerRequestRowState
    extends ConsumerState<_PendingManagerRequestRow> {
  bool _working = false;

  Future<void> _decide(bool approve) async {
    setState(() => _working = true);
    try {
      if (approve) {
        await ref
            .read(requestRepositoryProvider)
            .approveAsManager(widget.request.id);
      } else {
        await ref
            .read(requestRepositoryProvider)
            .rejectAsManager(widget.request.id);
      }
      ref.invalidate(pendingManagerApprovalRequestsProvider);
    } on RequestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${request.subject} — ${request.requesterName}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                request.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        if (_working)
          const Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else ...[
          TextButton(
            onPressed: () => _decide(false),
            child: const Text('Reject'),
          ),
          FilledButton(
            onPressed: () => _decide(true),
            child: const Text('Approve'),
          ),
        ],
      ],
    );
  }
}

/// Requests that have cleared manager approval and are awaiting the final
/// HR/Admin decision.
class _PendingHrApprovalSection extends ConsumerWidget {
  const _PendingHrApprovalSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingHrApprovalRequestsProvider);

    return FormSection(
      title: 'Requests Awaiting HR Approval',
      child: requestsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load pending requests.'),
        data: (requests) {
          if (requests.isEmpty) {
            return Text(
              'Nothing is awaiting HR approval right now.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < requests.length; i++) ...[
                _PendingHrRequestRow(request: requests[i]),
                if (i < requests.length - 1)
                  const Divider(height: 20, color: AppColors.borderSubtle),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PendingHrRequestRow extends ConsumerStatefulWidget {
  const _PendingHrRequestRow({required this.request});

  final EmployeeRequest request;

  @override
  ConsumerState<_PendingHrRequestRow> createState() =>
      _PendingHrRequestRowState();
}

class _PendingHrRequestRowState extends ConsumerState<_PendingHrRequestRow> {
  bool _working = false;

  Future<void> _decide(bool approve) async {
    setState(() => _working = true);
    try {
      if (approve) {
        await ref
            .read(requestRepositoryProvider)
            .approveAsHr(widget.request.id);
      } else {
        await ref.read(requestRepositoryProvider).rejectAsHr(widget.request.id);
      }
      ref.invalidate(pendingHrApprovalRequestsProvider);
    } on RequestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${request.subject} — ${request.requesterName}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                request.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Approved by manager: ${request.managerDecisionByName ?? '—'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (_working)
          const Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else ...[
          TextButton(
            onPressed: () => _decide(false),
            child: const Text('Reject'),
          ),
          FilledButton(
            onPressed: () => _decide(true),
            child: const Text('Approve'),
          ),
        ],
      ],
    );
  }
}
