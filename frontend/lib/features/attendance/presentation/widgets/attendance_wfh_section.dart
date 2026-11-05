import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../application/attendance_providers.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/exceptions/attendance_exception.dart';

/// HR marks days when the whole company works from home. On such a day the
/// machine is ignored: HR ticks who worked, and those people are simply
/// "present" — no clock in/out, grace time or late hours.
class AttendanceWfhSection extends ConsumerWidget {
  const AttendanceWfhSection({super.key});

  Future<void> _addDay(BuildContext context, WidgetRef ref) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Work from home day',
    );
    if (picked == null || !context.mounted) return;

    final note = await showAppDialog<String>(
      context: context,
      builder: (_) => const _NoteDialog(),
    );
    if (note == null || !context.mounted) return;

    final iso =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    try {
      await ref
          .read(attendanceRepositoryProvider)
          .addWfhDay(date: iso, note: note.isEmpty ? null : note);
      ref.invalidate(wfhDaysProvider);
      ref.invalidate(companyAttendanceProvider);
      ref.invalidate(myAttendanceProvider);
    } on AttendanceException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _removeDay(
    BuildContext context,
    WidgetRef ref,
    WfhDay day,
  ) async {
    try {
      await ref.read(attendanceRepositoryProvider).removeWfhDay(day.date);
      ref.invalidate(wfhDaysProvider);
      ref.invalidate(companyAttendanceProvider);
      ref.invalidate(myAttendanceProvider);
    } on AttendanceException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(wfhDaysProvider);
    final muted = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary);

    return FormSection(
      title: 'Work from home days',
      trailing: OutlinedButton.icon(
        key: const Key('add-wfh-day'),
        onPressed: () => _addDay(context, ref),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add a day'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'On a work-from-home day the machine is ignored: there are no '
            'clock times, grace time or late hours. You mark who worked and '
            'they count as present. Weekends and public holidays never count '
            'as absences or leave.',
            style: muted,
          ),
          const SizedBox(height: 12),
          daysAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            ),
            error: (_, _) => Row(
              children: [
                const Flexible(child: Text('Could not load these days.')),
                TextButton(
                  onPressed: () => ref.invalidate(wfhDaysProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
            data: (days) {
              if (days.isEmpty) {
                return Text('No work-from-home days set.', style: muted);
              }
              return Column(
                children: [
                  for (final day in days)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.home_work_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(formatDisplayDate(day.date)),
                      subtitle: Text(
                        '${day.note == null ? '' : '${day.note} · '}'
                        '${day.presentCount} marked present',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton(
                            key: Key('mark-wfh-${day.date}'),
                            onPressed: () => showAppDialog<void>(
                              context: context,
                              builder: (_) => _MarkAttendanceDialog(day: day),
                            ),
                            child: const Text('Mark attendance'),
                          ),
                          IconButton(
                            key: Key('remove-wfh-${day.date}'),
                            tooltip: 'Remove this day',
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => _removeDay(context, ref, day),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog();

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Work from home'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 200,
        decoration: const InputDecoration(
          labelText: 'Reason (optional)',
          hintText: 'e.g. Power outage at the office',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('wfh-note-add'),
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Add day'),
        ),
      ],
    );
  }
}

/// A checklist of the tracked employees: tick everyone who worked that day.
class _MarkAttendanceDialog extends ConsumerStatefulWidget {
  const _MarkAttendanceDialog({required this.day});

  final WfhDay day;

  @override
  ConsumerState<_MarkAttendanceDialog> createState() =>
      _MarkAttendanceDialogState();
}

class _MarkAttendanceDialogState extends ConsumerState<_MarkAttendanceDialog> {
  Set<String>? _selected;
  bool _saving = false;

  Future<void> _save(List<WfhDayEmployee> employees) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(attendanceRepositoryProvider)
          .setWfhDayAttendance(
            date: widget.day.date,
            employeeIds: _selected!.toList(),
          );
      ref.invalidate(wfhDaysProvider);
      ref.invalidate(companyAttendanceProvider);
      ref.invalidate(myAttendanceProvider);
      ref.invalidate(wfhDayAttendanceProvider(widget.day.date));
      if (mounted) Navigator.of(context).pop();
    } on AttendanceException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(wfhDayAttendanceProvider(widget.day.date));

    return AlertDialog(
      title: Text('Attendance — ${formatDisplayDate(widget.day.date)}'),
      content: SizedBox(
        width: 420,
        child: async.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const Text('Could not load the employees.'),
          data: (employees) {
            _selected ??= {
              for (final e in employees)
                if (e.present) e.employeeId,
            };
            final selected = _selected!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${selected.length} of ${employees.length} worked',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      key: const Key('wfh-select-all'),
                      onPressed: () => setState(
                        () => _selected = {
                          for (final e in employees) e.employeeId,
                        },
                      ),
                      child: const Text('Select all'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selected = {}),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final e in employees)
                          CheckboxListTile(
                            key: Key('wfh-present-${e.employeeId}'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: selected.contains(e.employeeId),
                            title: Text(e.employeeName),
                            subtitle: Text(e.employeeCode),
                            onChanged: (value) => setState(() {
                              if (value ?? false) {
                                selected.add(e.employeeId);
                              } else {
                                selected.remove(e.employeeId);
                              }
                            }),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('wfh-save'),
          onPressed: _saving || async.valueOrNull == null
              ? null
              : () => _save(async.value!),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
