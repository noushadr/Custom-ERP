import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/layout/app_nav_destination.dart';
import 'core/layout/responsive_scaffold.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/application/auth_providers.dart';
import 'features/authentication/application/auth_state.dart';
import 'features/authentication/presentation/pages/login_page.dart';
import 'features/authentication/presentation/widgets/impersonation_banner.dart';
import 'features/authentication/presentation/widgets/user_menu.dart';
import 'features/clients/presentation/pages/clients_projects_page.dart';
import 'features/clients/presentation/pages/project_detail_page.dart';
import 'features/employee/application/employee_providers.dart';
import 'features/employee/presentation/pages/admin_dashboard_page.dart';
import 'features/employee/presentation/pages/employee_directory_page.dart';
import 'features/employee/presentation/pages/employee_profile_page.dart';
import 'features/employee/presentation/pages/logs_page.dart';
import 'features/employee/presentation/pages/user_dashboard_page.dart';
import 'features/employee/presentation/widgets/notification_bell.dart';
import 'features/financial_reports/presentation/pages/financial_reports_page.dart';
import 'features/knowledge_base/presentation/pages/knowledge_base_page.dart';
import 'features/leads/presentation/pages/leads_page.dart';
import 'features/leave/presentation/pages/leave_page.dart';
import 'features/payroll/presentation/pages/payroll_page.dart';
import 'features/performance_reviews/presentation/pages/performance_review_detail_page.dart';
import 'features/performance_reviews/presentation/pages/performance_reviews_page.dart';
import 'features/requests/application/request_providers.dart';
import 'features/requests/presentation/pages/requests_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/tasks/application/task_providers.dart';
import 'features/tasks/domain/entities/task_status.dart';
import 'features/tasks/presentation/pages/task_detail_page.dart';
import 'features/tasks/presentation/pages/tasks_page.dart';

void main() {
  runApp(const ProviderScope(child: ZeraApp()));
}

class ZeraApp extends StatelessWidget {
  const ZeraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zera Creative ERP',
      theme: AppTheme.light,
      // Required by the Knowledge Base rich-text editor's toolbar
      // (flutter_quill), which looks up its tooltip strings via
      // FlutterQuillLocalizations.of(context).
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);

    return switch (state) {
      AuthInitial() || AuthLoading() => const _SplashScreen(),
      AuthAuthenticated() => const _HomeShell(),
      AuthUnauthenticated() => const LoginPage(),
    };
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// Placeholder navigation until the corresponding feature modules exist.
// Stable, full set — never resized. Visibility per role is filtered at
// render time in _HomeShellState.build, keyed off this list's indices.
// Icons stay outlined regardless of selection — a minimal, single-weight
// icon style, with the pastel indicator pill (not a glyph swap) carrying the
// selected state.
const _allDestinations = [
  AppNavDestination(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_outlined,
  ),
  AppNavDestination(
    label: 'User Dashboard',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_outlined,
  ),
  AppNavDestination(
    label: 'Employees',
    icon: Icons.people_outline,
    selectedIcon: Icons.people_outline,
  ),
  AppNavDestination(
    label: 'Requests',
    icon: Icons.assignment_outlined,
    selectedIcon: Icons.assignment_outlined,
  ),
  AppNavDestination(
    label: 'Leaves',
    icon: Icons.beach_access_outlined,
    selectedIcon: Icons.beach_access_outlined,
  ),
  AppNavDestination(
    label: 'Tasks',
    icon: Icons.checklist_outlined,
    selectedIcon: Icons.checklist_outlined,
  ),
  AppNavDestination(
    label: 'Performance Reviews',
    icon: Icons.rate_review_outlined,
    selectedIcon: Icons.rate_review_outlined,
  ),
  AppNavDestination(
    label: 'Knowledge Base',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book_outlined,
  ),
  AppNavDestination(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_outlined,
  ),
  AppNavDestination(
    label: 'Clients & Projects',
    icon: Icons.business_center_outlined,
    selectedIcon: Icons.business_center_outlined,
  ),
  AppNavDestination(
    label: 'Payroll',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_outlined,
  ),
  AppNavDestination(
    label: 'Leads',
    icon: Icons.person_search_outlined,
    selectedIcon: Icons.person_search_outlined,
  ),
  AppNavDestination(
    label: 'Financial Reports',
    icon: Icons.account_balance_outlined,
    selectedIcon: Icons.account_balance_outlined,
  ),
  AppNavDestination(
    label: 'Logs',
    icon: Icons.history_outlined,
    selectedIcon: Icons.history_outlined,
  ),
];

// Only Super Admin and HR/Manager see these in the nav; everyone else works
// entirely from User Dashboard, Requests, and (since 2026-09-02) Logs.
// Notifications live in the top bar (see NotificationBell), not the nav.
const _adminOnlyLabels = {
  'Dashboard',
  'Employees',
  'Settings',
  'Clients & Projects',
  'Payroll',
  'Leads',
  'Financial Reports',
};

// 'Logs' deliberately isn't in _adminOnlyLabels above (unlike before
// 2026-09-02) — every role sees it now: Super Admin/HR-Manager get the
// company-wide change feed (LogsPage's own `audit.viewAll` check), everyone
// else gets just their own change history, moved here from the bottom of
// User Dashboard the same day. It stays in _hrAndAdminOnlyLabels below only
// so the Super Admin's own sidebar keeps grouping it under "HR & Admin
// Features" rather than "General Features".

// Hidden from Super Admin/HR/Manager — they use Dashboard instead.
// Visible to everyone else.
const _nonAdminOnlyLabels = {'User Dashboard'};

// Stricter than _adminOnlyLabels: modules in this set are Super Admin only —
// Employees, Team Leads, and HR/Manager do not even see the nav entry. Was
// empty from 2026-08-23 (when the original Agency Reporting and Finances
// modules were removed) until 2026-08-25, when the new Financial Reports
// module became its first member — real company revenue/profit data,
// materially more sensitive than the shared-with-HR/Manager modules below.
// 'Leads' joined 2026-08-28 per explicit instruction, moving out of
// _hrAndAdminOnlyLabels below (it had been shared with HR/Manager since its
// 2026-08-23 launch) — the backend's `leads.manage` grant to HR/Manager was
// removed from seed.ts in the same change.
const _superAdminOnlyLabels = {'Financial Reports', 'Leads'};

// Modules shared between Super Admin and HR/Manager, but still off-limits to
// Team Lead/Employee (who are already excluded via _adminOnlyLabels above) —
// the original two are Admin Business Management modules; 'Logs' (the
// company-wide audit trail, formerly an Admin-Dashboard-only section) joined
// 2026-08-30 and isn't part of that section, just the same access tier. Used
// only to give the Super Admin's own sidebar a third, distinctly-labeled
// group — see ResponsiveScaffold.hrAdminSectionCount — so it's obvious at a
// glance which modules are Super-Admin-exclusive vs. shared with HR/Manager
// vs. general.
const _hrAndAdminOnlyLabels = {
  'Clients & Projects',
  'Payroll',
  'Logs',
};

bool _isAdminOrHr(WidgetRef ref) {
  final authState = ref.watch(authControllerProvider);
  return authState is AuthAuthenticated &&
      (authState.user.role == 'Super Admin' ||
          authState.user.role == 'HR/Manager');
}

bool _isSuperAdmin(WidgetRef ref) {
  final authState = ref.watch(authControllerProvider);
  return authState is AuthAuthenticated && authState.user.role == 'Super Admin';
}

/// How many pending items each nav destination should badge for the current
/// viewer — reusing the same "pending" signals the notification bell already
/// aggregates, so the nav and the bell never disagree. No permission guard on
/// the backend for most of these (mirrors NotificationBell) — naturally zero
/// for anyone the signal doesn't apply to.
Map<String, int> _navBadgeCounts(WidgetRef ref) {
  final authState = ref.watch(authControllerProvider);
  final authUser = authState is AuthAuthenticated ? authState.user : null;

  final myRequests = ref.watch(myRequestsProvider).valueOrNull ?? const [];
  final myOpenRequests = myRequests
      .where((r) => r.status != 'completed' && r.status != 'rejected')
      .length;
  final managerApprovals =
      ref.watch(pendingManagerApprovalRequestsProvider).valueOrNull ?? const [];
  final canSeeHrApprovals = authUser?.hasPermission('users.manage') ?? false;
  final hrApprovals = canSeeHrApprovals
      ? ref.watch(pendingHrApprovalRequestsProvider).valueOrNull ?? const []
      : const [];
  final requestsBadge =
      myOpenRequests + managerApprovals.length + hrApprovals.length;

  final myTasks = ref.watch(myTasksProvider).valueOrNull ?? const [];
  final tasksBadge = myTasks
      .where(
        (t) =>
            t.status != TaskStatus.completed &&
            t.status != TaskStatus.cancelled,
      )
      .length;

  final myProfile = ref.watch(myProfileProvider).valueOrNull;
  final profileIncomplete =
      myProfile != null && myProfile.profileCompletionPercentage < 100;

  return {
    'Requests': requestsBadge,
    'Tasks': tasksBadge,
    // Whichever of these two is actually visible depends on role — badging
    // both is harmless since only one is ever rendered at a time.
    if (profileIncomplete) 'Dashboard': 1,
    if (profileIncomplete) 'User Dashboard': 1,
  };
}

AppNavDestination _withBadge(AppNavDestination destination, int badgeCount) {
  if (badgeCount <= 0) return destination;
  return AppNavDestination(
    label: destination.label,
    icon: destination.icon,
    selectedIcon: destination.selectedIcon,
    comingSoon: destination.comingSoon,
    badgeCount: badgeCount,
  );
}

class _HomeShell extends ConsumerStatefulWidget {
  const _HomeShell();

  @override
  ConsumerState<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<_HomeShell> {
  // An index into _allDestinations — a stable identity independent of which
  // destinations are currently visible in the nav.
  int _selectedIndex = 0;

  // One Navigator per section (by _allDestinations index), so pushing a
  // sub-page (profile, edit, invite) only replaces that section's content —
  // the sidebar, top bar, and footer stay mounted. Keys must be created once
  // and stay stable across rebuilds, so this is sized to the full fixed set
  // rather than whatever subset is visible for the current role.
  late final List<GlobalKey<NavigatorState>> _sectionNavigatorKeys = [
    for (var i = 0; i < _allDestinations.length; i++) GlobalKey<NavigatorState>(),
  ];

  Widget _sectionRootFor(AppNavDestination destination) {
    switch (destination.label) {
      case 'Dashboard':
        return const AdminDashboardPage();
      case 'User Dashboard':
        return const UserDashboardPage();
      case 'Employees':
        return const EmployeeDirectoryPage();
      case 'Requests':
        return const RequestsPage();
      case 'Leaves':
        return const LeavePage();
      case 'Tasks':
        return const TasksPage();
      case 'Performance Reviews':
        return const PerformanceReviewsPage();
      case 'Knowledge Base':
        return const KnowledgeBasePage();
      case 'Settings':
        return const SettingsPage();
      case 'Clients & Projects':
        return const ClientsProjectsPage();
      case 'Payroll':
        return const PayrollPage();
      case 'Leads':
        return const LeadsPage();
      case 'Financial Reports':
        return const FinancialReportsPage();
      case 'Logs':
        return const LogsPage();
      default:
        return _ComingSoon(destination: destination);
    }
  }

  void _goToDestination(String label) {
    final index = _allDestinations.indexWhere((d) => d.label == label);
    if (index != -1) setState(() => _selectedIndex = index);
  }

  // Every section's Navigator lives inside an IndexedStack (see body below),
  // so it's already mounted even while a different section is showing —
  // this can push straight onto it without waiting for a rebuild.
  void _openEmployeeProfile(String employeeId) {
    final index = _allDestinations.indexWhere((d) => d.label == 'Employees');
    if (index == -1) return;
    final navigatorState = _sectionNavigatorKeys[index].currentState;
    navigatorState?.popUntil((route) => route.isFirst);
    navigatorState?.push(
      MaterialPageRoute(
        builder: (_) => EmployeeProfilePage(employeeId: employeeId),
      ),
    );
    setState(() => _selectedIndex = index);
  }

  void _openPerformanceReview(String reviewId) {
    final index = _allDestinations.indexWhere(
      (d) => d.label == 'Performance Reviews',
    );
    if (index == -1) return;
    final navigatorState = _sectionNavigatorKeys[index].currentState;
    navigatorState?.popUntil((route) => route.isFirst);
    navigatorState?.push(
      MaterialPageRoute(
        builder: (_) => PerformanceReviewDetailPage(reviewId: reviewId),
      ),
    );
    setState(() => _selectedIndex = index);
  }

  void _openTask(String taskId) {
    final index = _allDestinations.indexWhere((d) => d.label == 'Tasks');
    if (index == -1) return;
    final navigatorState = _sectionNavigatorKeys[index].currentState;
    navigatorState?.popUntil((route) => route.isFirst);
    navigatorState?.push(
      MaterialPageRoute(builder: (_) => TaskDetailPage(taskId: taskId)),
    );
    setState(() => _selectedIndex = index);
  }

  void _openProject(String projectId) {
    final index = _allDestinations.indexWhere(
      (d) => d.label == 'Clients & Projects',
    );
    if (index == -1) return;
    final navigatorState = _sectionNavigatorKeys[index].currentState;
    navigatorState?.popUntil((route) => route.isFirst);
    navigatorState?.push(
      MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: projectId)),
    );
    setState(() => _selectedIndex = index);
  }

  /// Routes a persisted notification's raw backend `linkTarget`/
  /// `linkEntityId` to a concrete destination — falls back to just
  /// switching to the relevant section when there's no specific entity to
  /// deep-link into.
  void _openNotification(String? linkTarget, String? linkEntityId) {
    switch (linkTarget) {
      case 'clients_projects':
        if (linkEntityId != null) {
          _openProject(linkEntityId);
        } else {
          _goToDestination('Clients & Projects');
        }
      case 'tasks':
        if (linkEntityId != null) {
          _openTask(linkEntityId);
        } else {
          _goToDestination('Tasks');
        }
      case 'leave':
        _goToDestination('Leaves');
      case 'performance_reviews':
        _goToDestination('Performance Reviews');
      case 'requests':
        _goToDestination('Requests');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdminOrHr = _isAdminOrHr(ref);
    final isSuperAdmin = _isSuperAdmin(ref);
    final badgeCounts = _navBadgeCounts(ref);

    final unsortedVisibleIndices = [
      for (var i = 0; i < _allDestinations.length; i++)
        if ((isAdminOrHr
                ? !_nonAdminOnlyLabels.contains(_allDestinations[i].label)
                : !_adminOnlyLabels.contains(_allDestinations[i].label)) &&
            (!_superAdminOnlyLabels.contains(_allDestinations[i].label) ||
                isSuperAdmin))
          i,
    ];
    // Only a Super Admin ever sees a mix of tiers (every other role either
    // sees none of the Super-Admin-exclusive modules, none of the
    // HR-and-admin ones, or neither) — so only for them, group the
    // Super-Admin-exclusive modules first, then the ones shared with
    // HR/Manager, then everything general — each with its own section
    // heading. Reordering the VISIBLE list here is safe and doesn't touch
    // `_allDestinations`'s stable order, which
    // `_sectionNavigatorKeys`/`IndexedStack` below key off directly — only
    // the nav's on-screen order changes.
    final visibleOriginalIndices = isSuperAdmin
        ? [
            ...unsortedVisibleIndices.where(
              (i) => _superAdminOnlyLabels.contains(_allDestinations[i].label),
            ),
            ...unsortedVisibleIndices.where(
              (i) => _hrAndAdminOnlyLabels.contains(_allDestinations[i].label),
            ),
            ...unsortedVisibleIndices.where(
              (i) =>
                  !_superAdminOnlyLabels.contains(_allDestinations[i].label) &&
                  !_hrAndAdminOnlyLabels.contains(_allDestinations[i].label),
            ),
          ]
        : unsortedVisibleIndices;
    final adminSectionCount = isSuperAdmin
        ? unsortedVisibleIndices
              .where(
                (i) =>
                    _superAdminOnlyLabels.contains(_allDestinations[i].label),
              )
              .length
        : 0;
    final hrAdminSectionCount = isSuperAdmin
        ? unsortedVisibleIndices
              .where(
                (i) =>
                    _hrAndAdminOnlyLabels.contains(_allDestinations[i].label),
              )
              .length
        : 0;
    final visibleDestinations = [
      for (final i in visibleOriginalIndices)
        _withBadge(
          _allDestinations[i],
          badgeCounts[_allDestinations[i].label] ?? 0,
        ),
    ];
    // Falls back to the first visible section if the previously-selected one
    // just disappeared (e.g. role changed via impersonation while on Admin
    // Dashboard/Employees/Settings — none of which the new role can see).
    final effectiveIndex = visibleOriginalIndices.contains(_selectedIndex)
        ? _selectedIndex
        : visibleOriginalIndices.first;

    return Column(
      children: [
        const ImpersonationBanner(),
        Expanded(
          child: ResponsiveScaffold(
            destinations: visibleDestinations,
            selectedIndex: visibleOriginalIndices.indexOf(effectiveIndex),
            onDestinationSelected: (visiblePosition) => setState(
              () => _selectedIndex = visibleOriginalIndices[visiblePosition],
            ),
            adminSectionCount: adminSectionCount,
            hrAdminSectionCount: hrAdminSectionCount,
            actions: [
              NotificationBell(
                onNavigate: (target) => _goToDestination(switch (target) {
                  NotificationLinkTarget.adminDashboard => 'Dashboard',
                  NotificationLinkTarget.userDashboard => 'User Dashboard',
                  NotificationLinkTarget.leavePage => 'Leaves',
                }),
                onOpenEmployeeProfile: _openEmployeeProfile,
                onOpenPerformanceReview: _openPerformanceReview,
                onOpenTask: _openTask,
                onOpenNotification: _openNotification,
              ),
              const SizedBox(width: 16),
              UserMenu(
                onSignOut: () =>
                    ref.read(authControllerProvider.notifier).logout(),
              ),
              const SizedBox(width: 8),
            ],
            body: IndexedStack(
              index: effectiveIndex,
              children: [
                for (var i = 0; i < _allDestinations.length; i++)
                  Navigator(
                    key: _sectionNavigatorKeys[i],
                    onGenerateRoute: (settings) => MaterialPageRoute(
                      builder: (_) => _sectionRootFor(_allDestinations[i]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.destination});

  final AppNavDestination destination;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                destination.selectedIcon,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${destination.label} — coming soon',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              "This section is on the roadmap and isn't built yet.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
