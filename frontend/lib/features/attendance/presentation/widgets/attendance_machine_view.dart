import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../employee/application/employee_providers.dart';
import '../../../employee/domain/entities/employee.dart';
import '../../application/attendance_providers.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/exceptions/attendance_exception.dart';

/// HR/Admin setup for the attendance machine: pull the latest scans, set the
/// working hours that decide "late", and link each machine user to an
/// employee.
class AttendanceMachineView extends ConsumerWidget {
  const AttendanceMachineView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SyncAndSettings(),
        SizedBox(height: 16),
        _MappingSection(),
      ],
    );
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _SyncAndSettings extends ConsumerStatefulWidget {
  const _SyncAndSettings();

  @override
  ConsumerState<_SyncAndSettings> createState() => _SyncAndSettingsState();
}

class _SyncAndSettingsState extends ConsumerState<_SyncAndSettings> {
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _grace = TextEditingController();
  bool _loaded = false;
  bool _syncing = false;
  bool _saving = false;

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    _grace.dispose();
    super.dispose();
  }

  void _fill(AttendanceSettings settings) {
    if (_loaded) return;
    _loaded = true;
    _start.text = settings.shiftStart;
    _end.text = settings.shiftEnd;
    _grace.text = '${settings.graceMinutes}';
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      final result = await ref.read(attendanceRepositoryProvider).sync();
      ref.invalidate(attendanceSettingsProvider);
      ref.invalidate(attendanceMappingProvider);
      ref.invalidate(companyAttendanceProvider);
      ref.invalidate(myAttendanceProvider);
      if (mounted) {
        _snack(
          context,
          'Synced — ${result.inserted} new scan(s) '
          '(${result.fetched} on the machine).',
        );
      }
    } on AttendanceException catch (error) {
      if (mounted) _snack(context, error.message);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _save() async {
    final grace = int.tryParse(_grace.text.trim());
    if (grace == null) {
      _snack(context, 'Grace period must be a number of minutes.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(attendanceRepositoryProvider)
          .updateSettings(
            shiftStart: _start.text.trim(),
            shiftEnd: _end.text.trim(),
            graceMinutes: grace,
          );
      ref.invalidate(attendanceSettingsProvider);
      ref.invalidate(companyAttendanceProvider);
      ref.invalidate(myAttendanceProvider);
      if (mounted) _snack(context, 'Working hours saved.');
    } on AttendanceException catch (error) {
      if (mounted) _snack(context, error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(attendanceSettingsProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => FormSection(
        child: Row(
          children: [
            const Flexible(child: Text('Could not load the settings.')),
            TextButton(
              onPressed: () => ref.invalidate(attendanceSettingsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (settings) {
        _fill(settings);
        final last = settings.lastSyncAt;
        return FormSection(
          title: 'Machine & working hours',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    settings.deviceConfigured
                        ? Icons.sensors
                        : Icons.sensors_off_outlined,
                    size: 18,
                    color: settings.deviceConfigured
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      !settings.deviceConfigured
                          ? 'No machine is configured on the server.'
                          : last == null
                          ? 'Not synced yet.'
                          : 'Last sync ${_formatWhen(last)} — '
                                '${settings.lastSyncMessage ?? ''}',
                    ),
                  ),
                  FilledButton.icon(
                    key: const Key('attendance-sync'),
                    onPressed: settings.deviceConfigured && !_syncing
                        ? _sync
                        : null,
                    icon: _syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync, size: 18),
                    label: const Text('Sync now'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'The server also pulls new scans from the machine every 10 '
                'minutes.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Divider(height: 28),
              Text(
                'Late is counted after the start time plus the grace period; '
                'early leave is counting from the end time. Times are '
                'Pakistan time.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 130,
                    child: TextField(
                      controller: _start,
                      decoration: const InputDecoration(
                        labelText: 'Shift starts',
                        hintText: '11:00',
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: TextField(
                      controller: _end,
                      decoration: const InputDecoration(
                        labelText: 'Shift ends',
                        hintText: '19:00',
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _grace,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Grace (minutes)',
                        isDense: true,
                      ),
                    ),
                  ),
                  FilledButton(
                    key: const Key('attendance-save-settings'),
                    onPressed: _saving ? null : _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

String _formatWhen(DateTime when) {
  final h = when.hour.toString().padLeft(2, '0');
  final m = when.minute.toString().padLeft(2, '0');
  return '${when.day}/${when.month}/${when.year} $h:$m';
}

class _MappingSection extends ConsumerStatefulWidget {
  const _MappingSection();

  @override
  ConsumerState<_MappingSection> createState() => _MappingSectionState();
}

class _MappingSectionState extends ConsumerState<_MappingSection> {
  bool _busy = false;

  Future<void> _autoLink() async {
    setState(() => _busy = true);
    try {
      final linked = await ref.read(attendanceRepositoryProvider).autoMap();
      ref.invalidate(attendanceMappingProvider);
      ref.invalidate(companyAttendanceProvider);
      if (mounted) {
        _snack(
          context,
          linked == 0
              ? 'No new names matched.'
              : 'Linked $linked machine user(s) by name.',
        );
      }
    } on AttendanceException catch (error) {
      if (mounted) _snack(context, error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setIgnored(AttendanceMapping row, bool ignored) async {
    try {
      await ref
          .read(attendanceRepositoryProvider)
          .setIgnored(deviceUserId: row.deviceUserId, ignored: ignored);
      ref.invalidate(attendanceMappingProvider);
      ref.invalidate(companyAttendanceProvider);
    } on AttendanceException catch (error) {
      if (mounted) _snack(context, error.message);
    }
  }

  Future<void> _link(
    AttendanceMapping row,
    String? newEmployeeId,
  ) async {
    try {
      final repository = ref.read(attendanceRepositoryProvider);
      // Unlinking: clear the employee currently linked to this machine user.
      if (newEmployeeId == null) {
        if (row.employeeId != null) {
          await repository.setMapping(employeeId: row.employeeId!);
        }
      } else {
        await repository.setMapping(
          employeeId: newEmployeeId,
          deviceUserId: row.deviceUserId,
        );
      }
      ref.invalidate(attendanceMappingProvider);
      ref.invalidate(companyAttendanceProvider);
    } on AttendanceException catch (error) {
      if (mounted) _snack(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mappingAsync = ref.watch(attendanceMappingProvider);
    final employeesAsync = ref.watch(employeeListProvider);

    return FormSection(
      title: 'Who is who on the machine',
      trailing: OutlinedButton.icon(
        key: const Key('attendance-auto-link'),
        onPressed: _busy ? null : _autoLink,
        icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
        label: const Text('Auto-link by name'),
      ),
      child: mappingAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => const Text('Could not load the machine users.'),
        data: (rows) {
          if (rows.isEmpty) {
            return const Text(
              'No machine users yet — press "Sync now" above to read them '
              'from the machine.',
            );
          }
          final employees = <Employee>[
            ...?employeesAsync.valueOrNull?.where(
              (e) =>
                  e.employmentStatus != 'resigned' &&
                  e.employmentStatus != 'terminated',
            ),
          ]..sort((a, b) => a.fullName.compareTo(b.fullName));
          final current = rows.where((r) => !r.ignored).toList();
          final former = rows.where((r) => r.ignored).toList();
          final linkedCount = current
              .where((r) => r.employeeId != null)
              .length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$linkedCount of ${current.length} machine users are linked to '
                'an employee. Unlinked people are not counted in attendance. '
                'Use the person-off button to hide someone who no longer '
                'works here.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              for (final row in current)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 56,
                        child: Text(
                          '#${row.deviceUserId}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          row.deviceName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String?>(
                          key: ValueKey(
                            'map-${row.deviceUserId}-${row.employeeId}',
                          ),
                          initialValue: row.employeeId,
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          hint: const Text('Not linked'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Not linked'),
                            ),
                            for (final e in employees)
                              DropdownMenuItem<String?>(
                                value: e.id,
                                child: Text(
                                  e.fullName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) => _link(row, value),
                        ),
                      ),
                      IconButton(
                        key: Key('ignore-${row.deviceUserId}'),
                        tooltip: 'No longer works here',
                        icon: const Icon(Icons.person_off_outlined, size: 20),
                        onPressed: () => _setIgnored(row, true),
                      ),
                    ],
                  ),
                ),
              if (former.isNotEmpty)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'No longer at Zera (${former.length})',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  children: [
                    for (final row in former)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(row.deviceName),
                        subtitle: Text('#${row.deviceUserId}'),
                        trailing: TextButton(
                          key: Key('restore-${row.deviceUserId}'),
                          onPressed: () => _setIgnored(row, false),
                          child: const Text('Restore'),
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
