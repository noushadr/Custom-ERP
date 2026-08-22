import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../../shared/widgets/permission_gate.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../application/automations_providers.dart';
import '../../domain/entities/automation.dart';
import '../../domain/entities/automation_execution_history_entry.dart';
import '../../domain/exceptions/automations_exception.dart';
import '../widgets/automation_labels.dart';

/// Admin-configurable catalog of the 3 fixed automations — Super-Admin-only
/// (gated by nav visibility in main.dart, and by `automations.manage` on
/// the backend routes). Not a generic rule builder: each card's trigger/
/// condition logic is fixed code, only isActive/daysBefore are editable.
class AutomationsPage extends ConsumerWidget {
  const AutomationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    if (authState is! AuthAuthenticated ||
        !authState.user.hasPermission('automations.manage')) {
      return const AccessDeniedView();
    }

    final automationsAsync = ref.watch(automationsListProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: automationsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Text(
              'Could not load automations. Please try again.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            data: (automations) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final automation in automations) ...[
                    _AutomationCard(automation: automation),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AutomationCard extends ConsumerStatefulWidget {
  const _AutomationCard({required this.automation});

  final Automation automation;

  @override
  ConsumerState<_AutomationCard> createState() => _AutomationCardState();
}

class _AutomationCardState extends ConsumerState<_AutomationCard> {
  late final TextEditingController _daysBeforeController;
  bool _saving = false;
  bool _running = false;
  String? _errorMessage;
  bool _historyExpanded = false;

  @override
  void initState() {
    super.initState();
    _daysBeforeController = TextEditingController(
      text: widget.automation.daysBefore?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _daysBeforeController.dispose();
    super.dispose();
  }

  Future<void> _toggleActive(bool value) async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(automationsRepositoryProvider)
          .updateAutomation(widget.automation.type, isActive: value);
      ref.invalidate(automationsListProvider);
    } on AutomationsException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveDaysBefore() async {
    final daysBefore = int.tryParse(_daysBeforeController.text);
    if (daysBefore == null || daysBefore < 1) {
      setState(() => _errorMessage = 'Enter a whole number of days, at least 1.');
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(automationsRepositoryProvider)
          .updateAutomation(widget.automation.type, daysBefore: daysBefore);
      ref.invalidate(automationsListProvider);
    } on AutomationsException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _runNow() async {
    setState(() {
      _running = true;
      _errorMessage = null;
    });
    try {
      await ref.read(automationsRepositoryProvider).runNow(widget.automation.type);
      ref.invalidate(automationHistoryProvider(widget.automation.type));
      if (mounted) setState(() => _historyExpanded = true);
    } on AutomationsException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final automation = widget.automation;
    final hasDaysBefore = automation.daysBefore != null;

    return FormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatAutomationTypeLabel(automation.type),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Switch(
                value: automation.isActive,
                onChanged: _saving ? null : _toggleActive,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            formatAutomationTypeDescription(automation.type),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (hasDaysBefore) ...[
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _daysBeforeController,
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Days before',
                      isDense: true,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: _saving ? null : _saveDaysBefore,
                  child: const Text('Save'),
                ),
              ],
              FilledButton.icon(
                onPressed: _running ? null : _runNow,
                icon: _running
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow, size: 16),
                label: const Text('Run Now'),
              ),
            ],
          ),
          if (automation.updatedByName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last changed by ${automation.updatedByName} · '
              '${formatDisplayDateTime(automation.updatedAt)}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 8),
          _HistorySection(
            type: automation.type,
            expanded: _historyExpanded,
            onExpansionChanged: (value) =>
                setState(() => _historyExpanded = value),
          ),
        ],
      ),
    );
  }
}

class _HistorySection extends ConsumerWidget {
  const _HistorySection({
    required this.type,
    required this.expanded,
    required this.onExpansionChanged,
  });

  final String type;
  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExpansionTile(
      // ExpansionTile only reads initiallyExpanded once, in initState — it
      // otherwise ignores rebuilds with a different value (e.g. this
      // widget auto-expanding after "Run Now"). Keying on the value we
      // want it to start at forces a fresh element when it changes.
      key: ValueKey(expanded),
      title: const Text('Run history'),
      tilePadding: EdgeInsets.zero,
      initiallyExpanded: expanded,
      onExpansionChanged: onExpansionChanged,
      children: [
        if (expanded)
          ref
              .watch(automationHistoryProvider(type))
              .when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const Text('Could not load run history.'),
                data: (entries) => entries.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No runs yet.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    : Column(
                        children: [
                          for (final entry in entries)
                            _HistoryRow(entry: entry),
                        ],
                      ),
              ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final AutomationExecutionHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final isError = entry.status == 'error';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 16,
            color: isError ? AppColors.error : AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isError
                      ? (entry.errorMessage ?? 'Run failed.')
                      : '${entry.itemsProcessed} item(s) processed, '
                            '${entry.notificationsCreated} notification(s) sent',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${formatDisplayDateTime(entry.runAt)} · '
                  '${entry.triggeredBy == 'cron' ? 'Scheduled' : 'Manual'}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
