import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../employee/presentation/widgets/employee_status_badges.dart';
import '../../domain/entities/client_health_factor.dart';
import '../../domain/entities/client_health_status.dart';

class ClientHealthBadge extends StatelessWidget {
  const ClientHealthBadge({super.key, required this.status, this.dense = false});

  final String status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ClientHealthStatus.healthy => ('Healthy', AppColors.success),
      ClientHealthStatus.attentionRequired => (
        'Attention Required',
        AppColors.warning,
      ),
      ClientHealthStatus.atRisk => ('At Risk', AppColors.error),
      _ => (status, AppColors.textSecondary),
    };
    return StatusBadge(label: label, color: color, dense: dense);
  }
}

String formatClientHealthStatusLabel(String status) => switch (status) {
  ClientHealthStatus.healthy => 'Healthy',
  ClientHealthStatus.attentionRequired => 'Attention Required',
  ClientHealthStatus.atRisk => 'At Risk',
  _ => status,
};

String formatClientHealthFactorLabel(String factor) => switch (factor) {
  ClientHealthFactor.payment => 'Payment',
  ClientHealthFactor.performance => 'Performance',
  ClientHealthFactor.delays => 'Delays',
  ClientHealthFactor.complaints => 'Complaints',
  ClientHealthFactor.communication => 'Communication',
  ClientHealthFactor.renewal => 'Renewal risk',
  _ => factor,
};
