import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/country_short_code.dart';
import '../../../../shared/widgets/permission_gate.dart';
import '../../../../shared/widgets/top_breakdown_panel.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../application/clients_providers.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/client_health_status.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/project_status.dart';
import '../../domain/entities/project_type.dart';
import '../widgets/client_health_badges.dart';
import '../widgets/project_badges.dart';
import 'client_detail_page.dart';
import 'client_editor_page.dart';
import 'project_detail_page.dart';
import 'project_editor_page.dart';

/// The Admin Business Management "Clients & Projects" module's root page —
/// shared by Super Admin and HR/Manager: gated by nav visibility in
/// main.dart, by `clients.manage` on every backend route this page calls,
/// and by its own `hasPermission` check at the top of `build()` (see
/// `AccessDeniedView`). A stats row up top, then Projects (default) /
/// Clients tabs.
class ClientsProjectsPage extends ConsumerWidget {
  const ClientsProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    if (authState is! AuthAuthenticated ||
        !authState.user.hasPermission('clients.manage')) {
      return const AccessDeniedView();
    }

    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            // The breakdown panels added enough content above the tabs that
            // it can no longer share a fixed-height `Expanded` region with
            // the tab content on shorter windows — the whole page scrolls
            // instead, with the tabs given their own generous fixed-height
            // region (each tab already scrolls its own list internally).
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SummaryRow(),
                  const SizedBox(height: 20),
                  const _ClientsBreakdownRow(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textSecondary,
                          indicatorColor: AppColors.primary,
                          tabs: [
                            Tab(text: 'Projects'),
                            Tab(text: 'Clients'),
                            Tab(text: 'Health'),
                          ],
                        ),
                      ),
                      _NewButtons(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(
                    height: 640,
                    child: TabBarView(
                      children: [_ProjectsTab(), _ClientsTab(), _HealthTab()],
                    ),
                  ),
                ],
              ),
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
    final clientsAsync = ref.watch(clientsListProvider(false));
    final projectsAsync = ref.watch(
      projectsListProvider((status: null, clientId: null)),
    );

    if (clientsAsync.isLoading || projectsAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }
    if (clientsAsync.hasError || projectsAsync.hasError) {
      return Text(
        'Could not load the summary.',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }

    final clients = clientsAsync.value ?? const [];
    final projects = projectsAsync.value ?? const [];

    final activeClientIds = projects
        .where((p) => p.status == ProjectStatus.active)
        .map((p) => p.clientId)
        .toSet();
    final activeClientsCount = clients
        .where((c) => activeClientIds.contains(c.id))
        .length;
    final retainerCount = projects
        .where((p) => p.type == ProjectType.retainer)
        .length;
    final oneTimeCount = projects
        .where((p) => p.type == ProjectType.oneTime)
        .length;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _StatTile(
          label: 'Total Clients',
          value: '${clients.length}',
          color: AppColors.primary,
          icon: Icons.business_outlined,
        ),
        _StatTile(
          label: 'Active Clients',
          value: '$activeClientsCount',
          color: AppColors.success,
          icon: Icons.verified_outlined,
        ),
        _StatTile(
          label: 'Monthly Retainers',
          value: '$retainerCount',
          color: AppColors.secondary,
          icon: Icons.event_repeat_outlined,
        ),
        _StatTile(
          label: 'One-Time Projects',
          value: '$oneTimeCount',
          color: AppColors.accentTeal,
          icon: Icons.flash_on_outlined,
        ),
      ],
    );
  }
}

/// Three "top N" categorical breakdowns for the whole module — countries
/// and lead source come from `Client`, services from every `Project`'s
/// assigned services — each its own panel with one representative hue,
/// mirroring the Leads page's identical breakdown row (shared widgets, see
/// `top_breakdown_panel.dart`).
class _ClientsBreakdownRow extends ConsumerWidget {
  const _ClientsBreakdownRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsListProvider(false));
    final projectsAsync = ref.watch(
      projectsListProvider((status: null, clientId: null)),
    );

    if (!clientsAsync.hasValue || !projectsAsync.hasValue) {
      return const SizedBox.shrink();
    }

    final clients = clientsAsync.value!;
    final projects = projectsAsync.value!;
    final serviceNames = projects.expand((p) => p.services.map((s) => s.name));

    final panels = [
      TopBreakdownPanel(
        title: 'Top Countries',
        icon: Icons.public_outlined,
        color: AppColors.primary,
        counts: computeTopCounts(clients, (c) => formatCountryFlag(c.country)),
      ),
      TopBreakdownPanel(
        title: 'Top Services',
        icon: Icons.design_services_outlined,
        color: AppColors.secondary,
        counts: computeTopCounts(serviceNames.toList(), (name) => name),
      ),
      TopBreakdownPanel(
        title: 'Top Lead Sources',
        icon: Icons.campaign_outlined,
        color: AppColors.accentTeal,
        counts: computeTopCounts(clients, (c) => c.leadSource),
      ),
    ];

    return TopBreakdownRow(panels: panels);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
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

/// (label, flex) for each spreadsheet-style column — shared between the
/// header and every data row so widths always line up. Mirrors the Leads
/// table's convention (`leads_page.dart`'s `_kLeadColumns`): a fixed
/// column set, flex-based `Expanded` cells (no horizontal scroll, which
/// would desync the header from the body), zebra striping, per-cell
/// tooltips for anything that might truncate.
const _kProjectColumns = [
  ('Client', 2),
  ('Project', 2),
  ('Type', 1),
  ('Status', 1),
  ('Start Date', 1),
  ('Package', 1),
  ('Employees', 2),
  ('Services', 2),
];

const _kClientColumns = [
  ('Company', 2),
  ('Contact', 2),
  ('Email', 2),
  ('Phone', 2),
  ('Country', 1),
  ('Industry', 1),
  ('Lead Source', 1),
];

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
        return _DataTableShell(
          header: const _TableHeader(columns: _kProjectColumns),
          itemCount: sorted.length,
          itemBuilder: (context, index) =>
              _ProjectTableRow(project: sorted[index], isEven: index.isEven),
        );
      },
    );
  }
}

class _ProjectTableRow extends StatelessWidget {
  const _ProjectTableRow({required this.project, required this.isEven});

  final Project project;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (project.status) {
      ProjectStatus.active => AppColors.success,
      ProjectStatus.onHold => AppColors.warning,
      ProjectStatus.completed => AppColors.textSecondary,
      ProjectStatus.cancelled => AppColors.error,
      _ => AppColors.textSecondary,
    };
    final employeesText = project.assignedEmployees.isEmpty
        ? '—'
        : project.assignedEmployees.map((e) => e.fullName).join(', ');
    final servicesText = project.services.isEmpty
        ? '—'
        : project.services.map((s) => s.name).join(', ');
    final cells = [
      project.clientName,
      project.name,
      formatProjectTypeLabel(project.type),
      formatProjectStatusLabel(project.status),
      project.startDate,
      project.packageName ?? '—',
      employeesText,
      servicesText,
    ];

    return _TableRow(
      isEven: isEven,
      columns: _kProjectColumns,
      cells: cells,
      cellColor: (i) => i == 3 ? statusColor : null,
      cellWeight: (i) => i == 0 ? FontWeight.w600 : null,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProjectDetailPage(projectId: project.id),
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
        return _DataTableShell(
          header: const _TableHeader(
            columns: _kClientColumns,
            trailingLabel: 'Health',
          ),
          itemCount: clients.length,
          itemBuilder: (context, index) =>
              _ClientTableRow(client: clients[index], isEven: index.isEven),
        );
      },
    );
  }
}

class _ClientTableRow extends StatelessWidget {
  const _ClientTableRow({required this.client, required this.isEven});

  final Client client;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    final cells = [
      client.companyName,
      client.primaryContactName ?? '—',
      client.primaryContactEmail ?? '—',
      client.primaryContactPhone ?? '—',
      formatCountryFlag(client.country) ?? '—',
      client.industry ?? '—',
      client.leadSource ?? '—',
    ];

    return _TableRow(
      isEven: isEven,
      columns: _kClientColumns,
      cells: cells,
      cellWeight: (i) => i == 0 ? FontWeight.w600 : null,
      trailing: ClientHealthBadge(status: client.healthStatus, dense: true),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ClientDetailPage(clientId: client.id),
        ),
      ),
    );
  }
}

/// The shared spreadsheet-table chrome (rounded card border, fixed header,
/// virtualized body) both the Projects and Clients tabs are built on.
class _DataTableShell extends StatelessWidget {
  const _DataTableShell({
    required this.header,
    required this.itemCount,
    required this.itemBuilder,
  });

  final Widget header;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

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
            header,
            Expanded(
              child: ListView.builder(
                itemCount: itemCount,
                itemBuilder: itemBuilder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.columns, this.trailingLabel});

  final List<(String, int)> columns;

  /// An extra fixed-width label at the end (e.g. "Health") for a column
  /// that renders a badge rather than plain text in each row.
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.fieldFill,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          for (final (label, flex) in columns)
            Expanded(
              flex: flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
            ),
          if (trailingLabel != null)
            SizedBox(
              width: 160,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  trailingLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.columns,
    required this.cells,
    required this.isEven,
    required this.onTap,
    this.cellColor,
    this.cellWeight,
    this.trailing,
  });

  final List<(String, int)> columns;
  final List<String> cells;
  final bool isEven;
  final VoidCallback onTap;

  /// Optional per-cell text color override, e.g. a status column colored by
  /// its value.
  final Color? Function(int index)? cellColor;

  /// Optional per-cell font-weight override, e.g. the first (identity)
  /// column rendered bolder than the rest.
  final FontWeight? Function(int index)? cellWeight;

  /// An extra fixed-width trailing cell rendering a widget rather than
  /// plain text (e.g. a status badge) — paired with `_TableHeader`'s
  /// `trailingLabel`.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodySmall;

    return InkWell(
      onTap: onTap,
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
            for (var i = 0; i < columns.length; i++)
              Expanded(
                flex: columns[i].$2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  child: Tooltip(
                    message: cells[i],
                    waitDuration: const Duration(milliseconds: 500),
                    child: Text(
                      cells[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: baseStyle?.copyWith(
                        color: cellColor?.call(i),
                        fontWeight: cellWeight?.call(i),
                      ),
                    ),
                  ),
                ),
              ),
            if (trailing != null)
              SizedBox(
                width: 160,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: trailing,
                ),
              ),
          ],
        ),
      ),
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
            ClientHealthBadge(status: client.healthStatus, dense: true),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _HealthTab extends ConsumerWidget {
  const _HealthTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(clientHealthSummaryProvider);
    final clientsAsync = ref.watch(clientsListProvider(false));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          summaryAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
            error: (_, _) => Text(
              'Could not load the health summary.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            data: (summary) => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatTile(
                  label: 'Healthy',
                  value: '${summary.healthyCount}',
                  color: AppColors.success,
                  icon: Icons.favorite_border,
                ),
                _StatTile(
                  label: 'Attention Required',
                  value: '${summary.attentionRequiredCount}',
                  color: AppColors.warning,
                  icon: Icons.warning_amber_outlined,
                ),
                _StatTile(
                  label: 'At Risk',
                  value: '${summary.atRiskCount}',
                  color: AppColors.error,
                  icon: Icons.error_outline,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Needs Attention',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          clientsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Text(
              'Could not load clients.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            data: (clients) {
              final atRisk = _sortedByWorstHealth(clients);
              if (atRisk.isEmpty) {
                return Text(
                  'No clients need attention right now.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < atRisk.length; i++) ...[
                    _ClientRow(client: atRisk[i]),
                    if (i < atRisk.length - 1)
                      const Divider(height: 1, color: AppColors.borderSubtle),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<Client> _sortedByWorstHealth(List<Client> clients) {
    const severity = {
      ClientHealthStatus.atRisk: 0,
      ClientHealthStatus.attentionRequired: 1,
    };
    final needsAttention = clients
        .where((c) => severity.containsKey(c.healthStatus))
        .toList();
    needsAttention.sort(
      (a, b) => severity[a.healthStatus]!.compareTo(severity[b.healthStatus]!),
    );
    return needsAttention;
  }
}
