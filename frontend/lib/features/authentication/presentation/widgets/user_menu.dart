import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../employee/application/employee_providers.dart';
import '../../../employee/domain/entities/employee.dart';
import '../../../employee/presentation/pages/edit_my_profile_page.dart';
import '../../../employee/presentation/widgets/employee_avatar.dart';
import '../../application/auth_providers.dart';
import '../../application/auth_state.dart';

enum _UserMenuAction { editProfile, signOut }

/// Avatar + dropdown shown in the top bar of the authenticated shell.
class UserMenu extends ConsumerWidget {
  const UserMenu({super.key, required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final email = state is AuthAuthenticated ? state.user.email : '';
    final role = state is AuthAuthenticated ? state.user.role : '';
    // Not every login is linked to an employee profile (e.g. a bootstrap
    // admin account) — valueOrNull falls back to initials-from-email below
    // whether that's because there's no linked profile, or it just hasn't
    // loaded yet.
    final profile = ref.watch(myProfileProvider).valueOrNull;
    final displayName = profile?.fullName ?? email;
    // First name only — "Hello, Jane" reads friendlier in a tight top-bar
    // strip than the full name, and falls back to the same display name the
    // avatar/menu use when there's no linked employee profile.
    final greetingName = profile?.firstName ?? displayName;
    // Desktop-only — the tablet/mobile AppBar has too little room for a
    // greeting alongside the title and the rest of these actions without
    // overflowing (confirmed by the widget-test suite before this guard).
    final showGreeting =
        MediaQuery.sizeOf(context).width >= Breakpoints.tabletMax;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showGreeting) ...[
          Text(
            'Hello, $greetingName',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
        ],
        _UserMenuButton(
          displayName: displayName,
          photoUrl: profile?.profilePhotoUrl,
          email: email,
          role: role,
          employee: profile,
          onSignOut: onSignOut,
        ),
      ],
    );
  }
}

class _UserMenuButton extends StatelessWidget {
  const _UserMenuButton({
    required this.displayName,
    required this.photoUrl,
    required this.email,
    required this.role,
    required this.employee,
    required this.onSignOut,
  });

  final String displayName;
  final String? photoUrl;
  final String email;
  final String role;
  // Null until myProfileProvider resolves (or for a login with no linked
  // employee row, e.g. a bootstrap admin account) — "Edit Profile" is
  // disabled rather than hidden in that case, same as the rest of this menu
  // never restructures itself while loading.
  final Employee? employee;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_UserMenuAction>(
      tooltip: 'Account menu',
      offset: const Offset(0, 44),
      onSelected: (action) => switch (action) {
        _UserMenuAction.editProfile => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EditMyProfilePage(employee: employee!),
          ),
        ),
        _UserMenuAction.signOut => onSignOut(),
      },
      itemBuilder: (context) => [
        PopupMenuItem<_UserMenuAction>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(email, style: Theme.of(context).textTheme.bodyMedium),
              Text(
                role,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<_UserMenuAction>(
          value: _UserMenuAction.editProfile,
          enabled: employee != null,
          child: const Row(
            children: [
              Icon(Icons.edit_outlined, size: 20),
              SizedBox(width: 12),
              Text('Edit profile'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<_UserMenuAction>(
          value: _UserMenuAction.signOut,
          child: Row(
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 12),
              Text('Sign out'),
            ],
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmployeeAvatar(fullName: displayName, photoUrl: photoUrl, radius: 16),
          const SizedBox(width: 4),
          const Icon(
            Icons.expand_more,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
