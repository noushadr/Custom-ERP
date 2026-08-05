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
    label: 'Directory',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
  ),
  AppNavDestination(
    label: 'Requests',
    icon: Icons.assignment_outlined,
    selectedIcon: Icons.assignment,
  ),
  AppNavDestination(
    label: 'Notifications',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications,
  ),
  AppNavDestination(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  ),
];

class _HomeShell extends ConsumerStatefulWidget {
  const _HomeShell();

  @override
  ConsumerState<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<_HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Zera Creative',
      destinations: _destinations,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      actions: [
        UserMenu(
          onProfileTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const EmployeeProfilePage(employeeId: null),
            ),
          ),
          onSignOut: () => ref.read(authControllerProvider.notifier).logout(),
        ),
        const SizedBox(width: 8),
      ],
      body: _bodyFor(_destinations[_selectedIndex], context),
    );
  }

  Widget _bodyFor(AppNavDestination destination, BuildContext context) {
    if (destination.label == 'Directory') {
      return const EmployeeDirectoryPage();
    }
    return _ComingSoon(destination: destination);
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
