import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/auth_providers.dart';
import '../../application/auth_state.dart';

/// Persistent strip shown across the whole app while a Super Admin is
/// logged in as someone else via "Login as".
class ImpersonationBanner extends ConsumerWidget {
  const ImpersonationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    if (state is! AuthAuthenticated || state.impersonatedBy == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: AppColors.warning.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_outlined,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Viewing as ${state.user.email} — signed in by '
              '${state.impersonatedBy!.email}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.warning),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).returnToAdmin(),
            child: const Text('Return to admin'),
          ),
        ],
      ),
    );
  }
}
