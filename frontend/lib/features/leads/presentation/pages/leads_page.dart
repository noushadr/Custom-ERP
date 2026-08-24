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

/// (label, flex) for each spreadsheet-style column — shared between the
/// header and every data row so widths always line up.
const _kLeadColumns = [
  ('Date', 2),
  ('Full Name', 3),
  ('Company', 3),
  ('Phone/Email', 3),
  ('Country', 2),
  ('Service Interested', 3),
  ('Lead Source', 2),
  ('Remarks', 4),
];

/// The Leads module's root page — a simple CRM-style list of prospective
/// clients gated by `leads.manage` (shared by Super Admin and HR/Manager,
/// same as Clients & Projects and Payroll). Rendered as a spreadsheet-style
/// grid (fixed columns, header row, zebra striping) rather than a card list,
/// since the underlying data is a flat, column-shaped import from a sales
/// log — a table reads closer to the source than a list of cards would.
class LeadsPage extends ConsumerWidget {
  const LeadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    if (authState is! AuthAuthenticated ||
        !authState.user.hasPermission('leads.manage')) {
      return const AccessDeniedView();
    }

    final leadsAsync = ref.watch(leadsListProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LeadEditorPage()),
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
              loading: () => const Center(child: CircularProgressIndicator()),
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
                return _LeadsTable(leads: leads);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadsStatsRow extends ConsumerWidget {
  const _LeadsStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(leadsListProvider);

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

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);

    bool onOrAfter(Lead lead, DateTime threshold) {
      final date = DateTime.tryParse(lead.leadDate);
      return date != null && !date.isBefore(threshold);
    }

    final newThisWeek = leads.where((l) => onOrAfter(l, weekAgo)).length;
    final newThisMonth = leads.where((l) => onOrAfter(l, monthStart)).length;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        MetricCard(
          label: 'Total Leads',
          value: '${leads.length}',
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
      ],
    );
  }
}

/// A spreadsheet-style grid: a fixed header row of column labels, then a
/// virtualized [ListView.builder] of aligned, fixed-column rows with
/// vertical cell dividers and alternating row shading — the "Excel" look
/// requested for this list, which a card-per-lead layout couldn't give at
/// 2,000+ rows without either scrolling forever or losing at-a-glance
/// scannability across columns.
class _LeadsTable extends StatelessWidget {
  const _LeadsTable({required this.leads});

  final List<Lead> leads;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            const _LeadsTableHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: leads.length,
                itemBuilder: (context, index) => _LeadsTableRow(
                  lead: leads[index],
                  isEven: index.isEven,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadsTableHeader extends StatelessWidget {
  const _LeadsTableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: AppColors.textSecondary,
    );
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.fieldFill,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          for (final (label, flex) in _kLeadColumns)
            Expanded(
              flex: flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(label, style: style),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeadsTableRow extends StatelessWidget {
  const _LeadsTableRow({required this.lead, required this.isEven});

  final Lead lead;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    final cellStyle = Theme.of(context).textTheme.bodySmall;
    final cells = [
      lead.leadDate,
      lead.fullName,
      lead.companyName ?? '—',
      lead.phone ?? lead.email ?? '—',
      lead.country ?? '—',
      lead.serviceInterested ?? '—',
      lead.leadSource ?? '—',
      lead.remarks ?? '—',
    ];

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LeadEditorPage(existingLead: lead)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isEven ? AppColors.surface : AppColors.canvasBackground,
          border: const Border(
            bottom: BorderSide(color: AppColors.borderSubtle),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            for (var i = 0; i < _kLeadColumns.length; i++)
              Expanded(
                flex: _kLeadColumns[i].$2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: i < _kLeadColumns.length - 1
                      ? const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: AppColors.borderSubtle),
                          ),
                        )
                      : null,
                  child: Tooltip(
                    message: cells[i],
                    waitDuration: const Duration(milliseconds: 500),
                    child: Text(
                      cells[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: i == 1
                          ? cellStyle?.copyWith(fontWeight: FontWeight.w600)
                          : cellStyle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
