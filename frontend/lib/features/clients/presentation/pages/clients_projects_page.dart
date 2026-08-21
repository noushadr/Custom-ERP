import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/currency_format.dart';
import '../../application/clients_providers.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/project.dart';
import '../widgets/project_badges.dart';
import 'client_detail_page.dart';
import 'client_editor_page.dart';
import 'project_detail_page.dart';
import 'project_editor_page.dart';

/// The Admin Business Management "Clients & Projects" module's root page —
/// Super-Admin-only (gated by nav visibility in main.dart, and by
/// `clients.manage` on every backend route this page calls). A stats row up
/// top, then Projects (default) / Clients tabs.
class ClientsProjectsPage extends ConsumerWidget {
  const ClientsProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SummaryRow(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: TabBar(
                        isScrollable: true,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        tabs: [
                          Tab(text: 'Projects'),
                          Tab(text: 'Clients'),
                        ],
                      ),
                    ),
                    _NewButtons(),
                  ],
                ),
                const SizedBox(height: 16),
                const Expanded(
                  child: TabBarView(
                    children: [_ProjectsTab(), _ClientsTab()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends ConsumerWidget {
  const _SummaryRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(projectsSummaryProvider);

    return summaryAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => Text(
        'Could not load the summary.',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      data: (summary) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _StatTile(
            label: 'Active Projects',
            value: '${summary.activeCount}',
            color: AppColors.success,
            icon: Icons.play_circle_outline,
          ),
          _StatTile(
            label: 'On Hold',
            value: '${summary.onHoldCount}',
            color: AppColors.warning,
            icon: Icons.pause_circle_outline,
          ),
          _StatTile(
            label: 'Completed',
            value: '${summary.completedCount}',
            color: AppColors.textSecondary,
            icon: Icons.check_circle_outline,
          ),
          _StatTile(
            label: 'Monthly Recurring Revenue',
            value:
                'PKR ${formatWholeAmount(summary.activeMonthlyRecurringRevenue)}',
            secondaryValue: formatUsdApprox(
              summary.activeMonthlyRecurringRevenue,
            ),
            color: AppColors.primary,
            icon: Icons.autorenew,
          ),
          _StatTile(
            label: 'One-time Revenue (This Year)',
            value: 'PKR ${formatWholeAmount(summary.oneTimeRevenueThisYear)}',
            secondaryValue: formatUsdApprox(summary.oneTimeRevenueThisYear),
            color: AppColors.accentTeal,
            icon: Icons.bolt_outlined,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.secondaryValue,
  });

  final String label;
  final String value;
  final String? secondaryValue;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (secondaryValue != null)
            Text(
              secondaryValue!,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
            ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _NewButtons extends StatelessWidget {
  const _NewButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ClientEditorPage()),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Client'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProjectEditorPage()),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Project'),
        ),
      ],
    );
  }
}

class _ProjectsTab extends ConsumerWidget {
  const _ProjectsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(
      projectsListProvider((status: null, clientId: null)),
    );

    return projectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Text(
          'Could not load projects. Please try again.',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (projects) {
        if (projects.isEmpty) {
          return const Center(child: Text('No projects yet.'));
        }
        final sorted = [...projects]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return ListView.separated(
          itemCount: sorted.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: AppColors.borderSubtle),
          itemBuilder: (context, index) => _ProjectRow(project: sorted[index]),
        );
      },
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProjectDetailPage(projectId: project.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${project.clientName} · PKR ${formatWholeAmount(project.netPrice)} net',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ProjectTypeBadge(type: project.type, dense: true),
            const SizedBox(width: 8),
            ProjectStatusBadge(status: project.status, dense: true),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _ClientsTab extends ConsumerWidget {
  const _ClientsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsListProvider(false));

    return clientsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Text(
          'Could not load clients. Please try again.',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (clients) {
        if (clients.isEmpty) {
          return const Center(child: Text('No clients yet.'));
        }
        return ListView.separated(
          itemCount: clients.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: AppColors.borderSubtle),
          itemBuilder: (context, index) => _ClientRow(client: clients[index]),
        );
      },
    );
  }
}

class _ClientRow extends StatelessWidget {
  const _ClientRow({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ClientDetailPage(clientId: client.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.companyName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (client.primaryContactName != null ||
                      client.primaryContactEmail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      [
                        client.primaryContactName,
                        client.primaryContactEmail,
                      ].whereType<String>().join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
