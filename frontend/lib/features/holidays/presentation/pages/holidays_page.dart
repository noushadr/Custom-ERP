import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../application/holiday_providers.dart';
import '../../domain/entities/holiday.dart';
import '../../domain/exceptions/holiday_exception.dart';

/// Lets Super Admin/HR-Manager view, add, edit, and delete the public
/// holiday list — Leave Management subtracts these dates (in addition to
/// weekends) when counting working days for a leave request. Requires
/// `leave.manage`.
class HolidaysPage extends ConsumerWidget {
  const HolidaysPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holidaysAsync = ref.watch(holidaysProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Holidays'),
        actions: [
          IconButton(
            tooltip: 'Add holiday',
            icon: const Icon(Icons.add),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const _HolidayFormDialog(holiday: null),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: holidaysAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(
              child: Text('Could not load holidays. Please try again.'),
            ),
            data: (holidays) {
              if (holidays.isEmpty) {
                return const Center(child: Text('No public holidays added yet.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: holidays.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _HolidayCard(holiday: holidays[index]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HolidayCard extends ConsumerWidget {
  const _HolidayCard({required this.holiday});

  final Holiday holiday;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete holiday?'),
        content: Text('This removes "${holiday.name}" from the holiday list.'),
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

    try {
      await ref.read(holidayRepositoryProvider).delete(holiday.id);
      ref.invalidate(holidaysProvider);
    } on HolidayException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FormSection(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holiday.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  formatDisplayDate(holiday.date),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => _HolidayFormDialog(holiday: holiday),
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: Icon(
              Icons.delete_outline,
              size: 20,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
    );
  }
}

class _HolidayFormDialog extends ConsumerStatefulWidget {
  const _HolidayFormDialog({required this.holiday});

  final Holiday? holiday;

  @override
  ConsumerState<_HolidayFormDialog> createState() =>
      _HolidayFormDialogState();
}

class _HolidayFormDialogState extends ConsumerState<_HolidayFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  DateTime? _date;
  bool _saving = false;
  String? _errorMessage;

  bool get _isEditing => widget.holiday != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.holiday?.name);
    _date = widget.holiday == null
        ? null
        : DateTime.parse(widget.holiday!.date);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      setState(() => _errorMessage = 'Date is required');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(holidayRepositoryProvider);
      final name = _nameController.text.trim();
      final date = _isoDate(_date!);
      if (_isEditing) {
        await repository.update(widget.holiday!.id, name: name, date: date);
      } else {
        await repository.create(name: name, date: date);
      }
      ref.invalidate(holidaysProvider);
      if (mounted) Navigator.of(context).pop();
    } on HolidayException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit holiday' : 'Add holiday'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _nameController,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(
                  _date == null ? 'Pick a date' : _isoDate(_date!),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Save changes' : 'Add holiday'),
        ),
      ],
    );
  }
}
