import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/currency_format.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/asset.dart';
import '../../domain/exceptions/employee_exception.dart';
import 'employee_status_badges.dart';

/// Company assets assigned to an employee — visible to the employee
/// themselves and to HR/Admin; only HR/Admin (when [canManage] is true) can
/// add, edit, or delete. [employeeId] is always the real employee id; set
/// [isSelf] to read via the self-service endpoint instead of the
/// `employees.manage`-gated one.
class EmployeeAssetsSection extends ConsumerStatefulWidget {
  const EmployeeAssetsSection({
    super.key,
    required this.employeeId,
    required this.isSelf,
    required this.canManage,
  });

  final String employeeId;
  final bool isSelf;
  final bool canManage;

  @override
  ConsumerState<EmployeeAssetsSection> createState() =>
      _EmployeeAssetsSectionState();
}

class _EmployeeAssetsSectionState extends ConsumerState<EmployeeAssetsSection> {
  String? _workingAssetId;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _invalidate() {
    ref.invalidate(employeeAssetsProvider(widget.employeeId));
    ref.invalidate(employeeAuditLogProvider(widget.employeeId));
    if (widget.isSelf) {
      ref.invalidate(myAssetsProvider);
      ref.invalidate(myAuditLogProvider);
    }
  }

  Future<void> _addAsset() async {
    final result = await showDialog<_AddAssetResult>(
      context: context,
      builder: (_) => const _AddAssetDialog(),
    );
    if (result == null) return;

    try {
      await ref
          .read(employeeRepositoryProvider)
          .createAndAssignAsset(
            widget.employeeId,
            name: result.name,
            value: result.value,
          );
      _invalidate();
    } on EmployeeException catch (error) {
      _showError(error.message);
    }
  }

  Future<void> _editAsset(Asset asset) async {
    final result = await showDialog<_EditAssetResult>(
      context: context,
      builder: (_) => _EditAssetDialog(asset: asset),
    );
    if (result == null) return;

    try {
      await ref
          .read(employeeRepositoryProvider)
          .updateAsset(
            widget.employeeId,
            asset.id,
            name: result.name,
            value: result.value,
          );
      _invalidate();
    } on EmployeeException catch (error) {
      _showError(error.message);
    }
  }

  Future<void> _delete(Asset asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete asset?'),
        content: Text(
          'This permanently removes "${asset.name}" from the system.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _workingAssetId = asset.id);
    try {
      await ref
          .read(employeeRepositoryProvider)
          .deleteAsset(widget.employeeId, asset.id);
      _invalidate();
    } on EmployeeException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _workingAssetId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = widget.isSelf
        ? ref.watch(myAssetsProvider)
        : ref.watch(employeeAssetsProvider(widget.employeeId));

    return FormSection(
      title: 'Assets',
      child: assetsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load assigned assets.'),
        data: (assets) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (assets.isEmpty)
                Text(
                  'No assets assigned.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                for (var i = 0; i < assets.length; i++) ...[
                  _AssetRow(
                    asset: assets[i],
                    isWorking: _workingAssetId == assets[i].id,
                    onEdit: widget.canManage ? () => _editAsset(assets[i]) : null,
                    onDelete: widget.canManage
                        ? () => _delete(assets[i])
                        : null,
                  ),
                  if (i < assets.length - 1)
                    const Divider(height: 20, color: AppColors.borderSubtle),
                ],
              if (widget.canManage) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addAsset,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add asset'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AssetStatusBadge extends StatelessWidget {
  const _AssetStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'available' => ('Available', AppColors.success),
      'assigned' => ('Assigned', AppColors.primary),
      'repair' => ('In Repair', AppColors.warning),
      'lost' => ('Lost', AppColors.error),
      'retired' => ('Retired', AppColors.textSecondary),
      _ => (status, AppColors.textSecondary),
    };
    return StatusBadge(label: label, color: color);
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({
    required this.asset,
    required this.isWorking,
    this.onEdit,
    this.onDelete,
  });

  final Asset asset;
  final bool isWorking;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        asset.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _AssetStatusBadge(status: asset.status),
                  ],
                ),
                if (asset.value != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'PKR ${formatAmount(asset.value!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (asset.assignedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Assigned ${formatDisplayDate(_isoDate(asset.assignedAt!))}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onEdit != null || onDelete != null) ...[
            const SizedBox(width: 8),
            if (isWorking)
              const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit',
                  onPressed: onEdit,
                ),
              if (onDelete != null)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  tooltip: 'Delete',
                  onPressed: onDelete,
                ),
            ],
          ],
        ],
      ),
    );
  }

  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

typedef _AddAssetResult = ({String name, double? value});

class _AddAssetDialog extends StatefulWidget {
  const _AddAssetDialog();

  @override
  State<_AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends State<_AddAssetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      name: _nameController.text.trim(),
      value: _valueController.text.trim().isEmpty
          ? null
          : double.tryParse(_valueController.text.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add asset'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Value in PKR (optional)',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return double.tryParse(value.trim()) == null
                      ? 'Enter a valid amount'
                      : null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}

typedef _EditAssetResult = ({String? name, double? value});

class _EditAssetDialog extends StatefulWidget {
  const _EditAssetDialog({required this.asset});

  final Asset asset;

  @override
  State<_EditAssetDialog> createState() => _EditAssetDialogState();
}

class _EditAssetDialogState extends State<_EditAssetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.asset.name);
    _valueController = TextEditingController(
      text: widget.asset.value == null
          ? null
          : _plainNumberText(widget.asset.value!),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      name: _nameController.text.trim(),
      value: _valueController.text.trim().isEmpty
          ? null
          : double.tryParse(_valueController.text.trim()),
    ) as _EditAssetResult);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit asset'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Value in PKR (optional)',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return double.tryParse(value.trim()) == null
                      ? 'Enter a valid amount'
                      : null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

/// Formats a raw double back into a plain editable number string (no
/// thousands separators) for pre-filling the value field — e.g. 150000.0 ->
/// "150000", 150000.5 -> "150000.5".
String _plainNumberText(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();
}
