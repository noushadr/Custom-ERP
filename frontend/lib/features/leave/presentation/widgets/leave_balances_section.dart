import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/leave_providers.dart';
import '../../domain/entities/leave_balance.dart';
import '../utils/leave_format_utils.dart';

/// The viewer's current-year leave balances, one card per leave type. Shared
/// between the Leave page and the User Dashboard so both show the exact same
/// figures, sourced from the same provider.
class LeaveBalancesSection extends ConsumerWidget {
  const LeaveBalancesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(myLeaveBalancesProvider);

    return balancesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => const Text('Could not load your leave balances.'),
      data: (balances) {
        if (balances.isEmpty) {
          return Text(
            'No leave balances yet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          );
        }
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final balance in balances) LeaveBalanceCard(balance: balance),
          ],
        );
      },
    );
  }
}

class LeaveBalanceCard extends StatelessWidget {
  const LeaveBalanceCard({super.key, required this.balance});

  final LeaveBalance balance;

  @override
  Widget build(BuildContext context) {
    final color = parseLeaveColor(balance.colorHex) ?? AppColors.primary;
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  balance.leaveTypeName,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatLeaveDays(balance.remaining),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'remaining of ${formatLeaveDays(balance.allocated)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
