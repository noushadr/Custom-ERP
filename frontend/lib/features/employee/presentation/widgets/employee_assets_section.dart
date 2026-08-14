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
/// add, edit, or unassign. [employeeId] is always the real employee id; set
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
    ref.invalidate(availableAssetsProvider);
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
      if (result.isNew) {
        await ref
            .read(employeeRepositoryProvider)
            .createAndAssignAsset(
              widget.employeeId,
              name: result.name!,
              value: result.value,
            );
      } else {
        await ref
            .read(employeeRepositoryProvider)
            .assignExistingAsset(widget.employeeId, result.assetId!);
      }
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

  Future<void> _unassign(Asset asset) async {
    setState(() => _workingAssetId = asset.id);
    try {
      await ref
          .read(employeeRepositoryProvider)
          .unassignAsset(widget.employeeId, asset.id);
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
                    onUnassign: widget.canManage
                        ? () => _unassign(assets[i])
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
    this.onUnassign,
  });

  final Asset asset;
  final bool isWorking;
  final VoidCallback? onEdit;
  final VoidCallback? onUnassign;

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
          if (onEdit != null || onUnassign != null) ...[
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
              if (onUnassign != null)
                TextButton(onPressed: onUnassign, child: const Text('Unassign')),
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

typedef _AddAssetResult = ({
  bool isNew,
  String? assetId,
  String? name,
  double? value,
});

class _AddAssetDialog extends ConsumerStatefulWidget {
  const _AddAssetDialog();

  @override
  ConsumerState<_AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends ConsumerState<_AddAssetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  bool _isNew = true;
  String? _selectedAssetId;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isNew) {
      if (!_formKey.currentState!.validate()) return;
      Navigator.of(context).pop((
        isNew: true,
        assetId: null,
        name: _nameController.text.trim(),
        value: _valueController.text.trim().isEmpty
            ? null
            : double.tryParse(_valueController.text.trim()),
      ) as _AddAssetResult);
      return;
    }

    if (_selectedAssetId == null) {
      setState(() => _errorMessage = 'Choose an asset to assign.');
      return;
    }
    Navigator.of(context).pop((
      isNew: false,
      assetId: _selectedAssetId,
      name: null,
      value: null,
    ) as _AddAssetResult);
  }

  @override
  Widget build(BuildContext context) {
    final availableAsync = ref.watch(availableAssetsProvider);

    return AlertDialog(
      title: const Text('Add asset'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('New asset')),
                ButtonSegment(value: false, label: Text('Existing asset')),
              ],
              selected: {_isNew},
              onSelectionChanged: (selection) =>
                  setState(() => _isNew = selection.first),
            ),
            const SizedBox(height: 16),
            if (_isNew)
              Form(
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
              )
            else
              availableAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Could not load available assets.'),
                data: (available) {
                  if (available.isEmpty) {
                    return const Text('No unassigned assets available.');
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedAssetId,
                    decoration: const InputDecoration(labelText: 'Asset'),
                    items: [
                      for (final asset in available)
                        DropdownMenuItem(
                          value: asset.id,
                          child: Text(asset.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _selectedAssetId = value),
                  );
                },
              ),
          ],
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
