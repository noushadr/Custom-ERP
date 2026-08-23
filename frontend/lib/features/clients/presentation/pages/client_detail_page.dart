import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../employee/presentation/widgets/employee_status_badges.dart';
import '../../application/clients_providers.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/client_health_factor.dart';
import '../../domain/entities/client_health_history_entry.dart';
import '../../domain/entities/client_health_status.dart';
import '../../domain/exceptions/client_exception.dart';
import '../widgets/client_health_badges.dart';
import '../widgets/project_badges.dart';
import 'client_editor_page.dart';
import 'project_detail_page.dart';

class ClientDetailPage extends ConsumerWidget {
  const ClientDetailPage({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientProvider(clientId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client'),
        actions: [
          clientAsync.maybeWhen(
            data: (client) => TextButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ClientEditorPage(existingClient: client),
                  ),
                );
                ref.invalidate(clientProvider(clientId));
                ref.invalidate(clientsListProvider(false));
                ref.invalidate(clientsListProvider(true));
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: clientAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Could not load this client.'),
            ),
            data: (client) => _ClientDetailBody(client: client),
          ),
        ),
      ),
    );
  }
}

class _ClientDetailBody extends ConsumerWidget {
  const _ClientDetailBody({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(
      projectsListProvider((status: null, clientId: client.id)),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  client.companyName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (client.isArchived)
                const StatusBadge(label: 'Archived', color: AppColors.error),
            ],
          ),
          if (client.industry != null) ...[
            const SizedBox(height: 4),
            Text(
              client.industry!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 16),
          FormSection(
            title: 'Health',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClientHealthBadge(status: client.healthStatus),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await showDialog<void>(
                          context: context,
                          builder: (_) => _UpdateHealthDialog(client: client),
                        );
                        ref.invalidate(clientProvider(client.id));
                        ref.invalidate(clientsListProvider(false));
                        ref.invalidate(clientsListProvider(true));
                        ref.invalidate(clientHealthHistoryProvider(client.id));
                        ref.invalidate(clientHealthSummaryProvider);
                      },
                      icon: const Icon(Icons.favorite_border, size: 16),
                      label: const Text('Update Health'),
                    ),
                  ],
                ),
                if (client.healthFactors.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final factor in client.healthFactors)
                        Chip(label: Text(formatClientHealthFactorLabel(factor))),
                    ],
                  ),
                ],
                if (client.healthNotes != null &&
                    client.healthNotes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(client.healthNotes!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          FormSection(
            title: 'Health History',
            child: ref
                .watch(clientHealthHistoryProvider(client.id))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Text('Could not load health history.'),
                  data: (history) => history.isEmpty
                      ? Text(
                          'No health updates yet.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < history.length; i++) ...[
                              _HealthHistoryRow(entry: history[i]),
                              if (i < history.length - 1)
                                const Divider(
                                  height: 16,
                                  color: AppColors.borderSubtle,
                                ),
                            ],
                          ],
                        ),
                ),
          ),
          const SizedBox(height: 16),
          FormSection(
            title: 'Contact',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (client.primaryContactName != null)
                  Text('Contact: ${client.primaryContactName}'),
                if (client.primaryContactEmail != null)
                  Text('Email: ${client.primaryContactEmail}'),
                if (client.primaryContactPhone != null)
                  Text('Phone: ${client.primaryContactPhone}'),
                if (client.website != null) Text('Website: ${client.website}'),
                if (client.country != null) Text('Country: ${client.country}'),
                if (client.address != null) Text('Address: ${client.address}'),
                if (client.leadSource != null)
                  Text('Lead source: ${client.leadSource}'),
                if (client.primaryContactName == null &&
                    client.primaryContactEmail == null &&
                    client.primaryContactPhone == null &&
                    client.website == null &&
                    client.country == null &&
                    client.address == null &&
                    client.leadSource == null)
                  Text(
                    'No contact details yet.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (client.notes != null && client.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            FormSection(title: 'Notes', child: Text(client.notes!)),
          ],
          const SizedBox(height: 16),
          FormSection(
            title: 'Projects',
            child: projectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('Could not load projects.'),
              data: (projects) => projects.isEmpty
                  ? Text(
                      'No projects for this client yet.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < projects.length; i++) ...[
                          InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProjectDetailPage(
                                  projectId: projects[i].id,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      projects[i].name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ),
                                  ProjectStatusBadge(
                                    status: projects[i].status,
                                    dense: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (i < projects.length - 1)
                            const Divider(
                              height: 1,
                              color: AppColors.borderSubtle,
                            ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthHistoryRow extends StatelessWidget {
  const _HealthHistoryRow({required this.entry});

  final ClientHealthHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClientHealthBadge(status: entry.previousStatus, dense: true),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward, size: 14),
            ),
            ClientHealthBadge(status: entry.newStatus, dense: true),
            const Spacer(),
            Text(
              formatDisplayDateTime(entry.createdAt),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'By ${entry.actorName}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        if (entry.factors.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final factor in entry.factors)
                Chip(
                  label: Text(
                    formatClientHealthFactorLabel(factor),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
        if (entry.notes != null && entry.notes!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(entry.notes!),
        ],
      ],
    );
  }
}

class _UpdateHealthDialog extends ConsumerStatefulWidget {
  const _UpdateHealthDialog({required this.client});

  final Client client;

  @override
  ConsumerState<_UpdateHealthDialog> createState() =>
      _UpdateHealthDialogState();
}

class _UpdateHealthDialogState extends ConsumerState<_UpdateHealthDialog> {
  late String _status;
  late Set<String> _selectedFactors;
  late final TextEditingController _notesController;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _status = widget.client.healthStatus;
    _selectedFactors = {...widget.client.healthFactors};
    _notesController = TextEditingController(text: widget.client.healthNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final notes = _notesController.text.trim();
      await ref
          .read(clientsRepositoryProvider)
          .updateClientHealth(
            widget.client.id,
            status: _status,
            factors: _selectedFactors.toList(),
            notes: notes.isEmpty ? null : notes,
          );
      ref.invalidate(clientsListProvider(false));
      ref.invalidate(clientsListProvider(true));
      ref.invalidate(clientProvider(widget.client.id));
      ref.invalidate(clientHealthHistoryProvider(widget.client.id));
      ref.invalidate(clientHealthSummaryProvider);
      if (mounted) Navigator.of(context).pop();
    } on ClientException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Health'),
      content: SizedBox(
        width: 420,
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
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final status in ClientHealthStatus.values)
                  DropdownMenuItem(
                    value: status,
                    child: Text(formatClientHealthStatusLabel(status)),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) setState(() => _status = value);
                    },
            ),
            const SizedBox(height: 16),
            Text('Factors', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final factor in ClientHealthFactor.values)
                  FilterChip(
                    label: Text(formatClientHealthFactorLabel(factor)),
                    selected: _selectedFactors.contains(factor),
                    onSelected: _saving
                        ? null
                        : (selected) => setState(() {
                            if (selected) {
                              _selectedFactors.add(factor);
                            } else {
                              _selectedFactors.remove(factor);
                            }
                          }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              enabled: !_saving,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
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
              : const Text('Save'),
        ),
      ],
    );
  }
}
