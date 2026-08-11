import 'package:flutter/material.dart';
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
import 'features/employee/presentation/pages/admin_dashboard_page.dart';
import 'features/employee/presentation/pages/employee_directory_page.dart';
import 'features/employee/presentation/pages/employee_profile_page.dart';
import 'features/employee/presentation/pages/user_dashboard_page.dart';
import 'features/employee/presentation/widgets/notification_bell.dart';
import 'features/requests/presentation/pages/requests_page.dart';

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
const _allDestinations = [
  AppNavDestination(
    label: 'Admin Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  AppNavDestination(
    label: 'User Dashboard',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  AppNavDestination(
    label: 'Employees',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
  ),
  AppNavDestination(
    label: 'Requests',
    icon: Icons.assignment_outlined,
    selectedIcon: Icons.assignment,
  ),
  AppNavDestination(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    comingSoon: true,
  ),
];

// Only Super Admin and HR/Manager see these in the nav; everyone else works
// entirely from User Dashboard and Requests. Notifications live in the top
// bar (see NotificationBell), not the nav.
const _adminOnlyLabels = {'Admin Dashboard', 'Employees', 'Settings'};

// Hidden from Super Admin/HR/Manager — they use Admin Dashboard instead.
// Visible to everyone else.
const _nonAdminOnlyLabels = {'User Dashboard'};

bool _isAdminOrHr(WidgetRef ref) {
  final authState = ref.watch(authControllerProvider);
  return authState is AuthAuthenticated &&
      (authState.user.role == 'Super Admin' ||
          authState.user.role == 'HR/Manager');
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
      case 'Admin Dashboard':
        return const AdminDashboardPage();
      case 'User Dashboard':
        return const UserDashboardPage();
      case 'Employees':
        return const EmployeeDirectoryPage();
      case 'Requests':
        return const RequestsPage();
      default:
        return _ComingSoon(destination: destination);
    }
  }

  void _goToDestination(String label) {
    final index = _allDestinations.indexWhere((d) => d.label == label);
    if (index != -1) setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isAdminOrHr = _isAdminOrHr(ref);

    final visibleOriginalIndices = [
      for (var i = 0; i < _allDestinations.length; i++)
        if (isAdminOrHr
            ? !_nonAdminOnlyLabels.contains(_allDestinations[i].label)
            : !_adminOnlyLabels.contains(_allDestinations[i].label))
          i,
    ];
    final visibleDestinations = [
      for (final i in visibleOriginalIndices) _allDestinations[i],
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
            actions: [
              NotificationBell(
                onNavigate: (target) => _goToDestination(switch (target) {
                  NotificationLinkTarget.adminDashboard => 'Admin Dashboard',
                  NotificationLinkTarget.userDashboard => 'User Dashboard',
                }),
              ),
              const SizedBox(width: 16),
              UserMenu(
                onProfileTap: () => _sectionNavigatorKeys[effectiveIndex]
                    .currentState!
                    .push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const EmployeeProfilePage(employeeId: null),
                      ),
                    ),
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
