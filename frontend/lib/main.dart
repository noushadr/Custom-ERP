import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/layout/app_nav_destination.dart';
import 'core/layout/responsive_scaffold.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/application/auth_providers.dart';
import 'features/authentication/application/auth_state.dart';
import 'features/authentication/presentation/pages/login_page.dart';
import 'features/authentication/presentation/widgets/user_menu.dart';
import 'features/employee/presentation/pages/dashboard_page.dart';
import 'features/employee/presentation/pages/employee_directory_page.dart';
import 'features/employee/presentation/pages/employee_profile_page.dart';

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
const _destinations = [
  AppNavDestination(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
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
    comingSoon: true,
  ),
  AppNavDestination(
    label: 'Notifications',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications,
    comingSoon: true,
  ),
  AppNavDestination(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    comingSoon: true,
  ),
];

class _HomeShell extends ConsumerStatefulWidget {
  const _HomeShell();

  @override
  ConsumerState<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<_HomeShell> {
  int _selectedIndex = 0;

  // One Navigator per section, so pushing a sub-page (profile, edit, invite)
  // only replaces that section's content — the sidebar, top bar, and footer
  // stay mounted. Keys must be created once and stay stable across rebuilds.
  late final List<GlobalKey<NavigatorState>> _sectionNavigatorKeys = [
    for (var i = 0; i < _destinations.length; i++) GlobalKey<NavigatorState>(),
  ];

  Widget _sectionRootFor(AppNavDestination destination) {
    switch (destination.label) {
      case 'Dashboard':
        return const DashboardPage();
      case 'Employees':
        return const EmployeeDirectoryPage();
      default:
        return _ComingSoon(destination: destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      destinations: _destinations,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      actions: [
        UserMenu(
          onProfileTap: () => _sectionNavigatorKeys[_selectedIndex]
              .currentState!
              .push(
                MaterialPageRoute(
                  builder: (_) => const EmployeeProfilePage(employeeId: null),
                ),
              ),
          onSignOut: () => ref.read(authControllerProvider.notifier).logout(),
        ),
        const SizedBox(width: 8),
      ],
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          for (var i = 0; i < _destinations.length; i++)
            Navigator(
              key: _sectionNavigatorKeys[i],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => _sectionRootFor(_destinations[i]),
              ),
            ),
        ],
      ),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                destination.selectedIcon,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
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
