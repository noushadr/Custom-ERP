import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../../shared/widgets/permission_gate.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../application/leads_providers.dart';
import '../../domain/entities/lead.dart';
import 'lead_editor_page.dart';

/// The Leads module's root page — a simple CRM-style list of prospective
/// clients gated by `leads.manage` (shared by Super Admin and HR/Manager,
/// same as Clients & Projects and Payroll).
class LeadsPage extends ConsumerStatefulWidget {
  const LeadsPage({super.key});

  @override
  ConsumerState<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends ConsumerState<LeadsPage> {
  bool _includeArchived = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    if (authState is! AuthAuthenticated ||
        !authState.user.hasPermission('leads.manage')) {
      return const AccessDeniedView();
    }

    final leadsAsync = ref.watch(leadsListProvider(_includeArchived));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Leads',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    'Show archived',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Switch(
                    value: _includeArchived,
                    onChanged: (value) =>
                        setState(() => _includeArchived = value),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LeadEditorPage(),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Lead'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _LeadsStatsRow(),
              const SizedBox(height: 16),
              Expanded(
                child: leadsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: Text(
                      'Could not load leads. Please try again.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  data: (leads) {
                    if (leads.isEmpty) {
                      return const Center(child: Text('No leads yet.'));
                    }
                    return ListView.separated(
                      itemCount: leads.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        color: AppColors.borderSubtle,
                      ),
                      itemBuilder: (context, index) =>
                          _LeadRow(lead: leads[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadsStatsRow extends ConsumerWidget {
  const _LeadsStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(leadsListProvider(true));

    if (leadsAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }
    if (leadsAsync.hasError) {
      return Text(
        'Could not load the summary.',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }

    final leads = leadsAsync.value ?? const [];
    final active = leads.where((l) => !l.isArchived).toList();
    final archivedCount = leads.length - active.length;

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);

    bool onOrAfter(Lead lead, DateTime threshold) {
      final date = DateTime.tryParse(lead.leadDate);
      return date != null && !date.isBefore(threshold);
    }

    final newThisWeek = active.where((l) => onOrAfter(l, weekAgo)).length;
    final newThisMonth = active.where((l) => onOrAfter(l, monthStart)).length;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        MetricCard(
          label: 'Total Leads',
          value: '${active.length}',
          color: AppColors.primary,
          icon: Icons.person_search_outlined,
        ),
        MetricCard(
          label: 'New This Week',
          value: '$newThisWeek',
          color: AppColors.secondary,
          icon: Icons.bolt_outlined,
        ),
        MetricCard(
          label: 'New This Month',
          value: '$newThisMonth',
          color: AppColors.accentTeal,
          icon: Icons.calendar_month_outlined,
        ),
        MetricCard(
          label: 'Archived',
          value: '$archivedCount',
          color: AppColors.textSecondary,
          icon: Icons.archive_outlined,
        ),
      ],
    );
  }
}

class _LeadRow extends StatelessWidget {
  const _LeadRow({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final companyLine = [
      lead.companyName,
      lead.country,
    ].whereType<String>().where((s) => s.isNotEmpty).toList();
    final contact = lead.phone ?? lead.email;
    final contactLine = [
      contact,
      lead.leadSource,
    ].whereType<String>().where((s) => s.isNotEmpty).toList();
    final secondaryStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary);

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LeadEditorPage(existingLead: lead),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          lead.fullName,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (lead.isArchived) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Archived',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (companyLine.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(companyLine.join(' · '), style: secondaryStyle),
                  ],
                  if (contactLine.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(contactLine.join(' · '), style: secondaryStyle),
                  ],
                  if (lead.remarks != null && lead.remarks!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      lead.remarks!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: secondaryStyle?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lead.serviceInterested != null &&
                    lead.serviceInterested!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      lead.serviceInterested!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(lead.leadDate, style: secondaryStyle),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
