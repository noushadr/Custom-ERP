import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../employee/application/employee_providers.dart';
import '../../../employee/presentation/widgets/employee_avatar.dart';
import '../../application/auth_providers.dart';
import '../../application/auth_state.dart';

enum _UserMenuAction { signOut }

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

    return PopupMenuButton<_UserMenuAction>(
      tooltip: 'Account menu',
      offset: const Offset(0, 44),
      onSelected: (action) => switch (action) {
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
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
          EmployeeAvatar(
            fullName: displayName,
            photoUrl: profile?.profilePhotoUrl,
            radius: 16,
          ),
          const SizedBox(width: 4),
          const Icon(Icons.expand_more, size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
