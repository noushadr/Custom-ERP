import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/permission_gate.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../application/leads_providers.dart';
import '../../domain/entities/lead.dart';
import 'lead_editor_page.dart';

/// The Leads module's root page — a simple CRM-style list of prospective
/// clients gated by `leads.manage` (shared by Super Admin and HR/Manager,
/// same as Clients & Projects and Payroll).
class LeadsPage extends ConsumerStatefulWidget {
  const LeadsPage({super.key});

  @override
  ConsumerState<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends ConsumerState<LeadsPage> {
  bool _includeArchived = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    if (authState is! AuthAuthenticated ||
        !authState.user.hasPermission('leads.manage')) {
      return const AccessDeniedView();
    }

    final leadsAsync = ref.watch(leadsListProvider(_includeArchived));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Leads',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    'Show archived',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Switch(
                    value: _includeArchived,
                    onChanged: (value) =>
                        setState(() => _includeArchived = value),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LeadEditorPage(),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Lead'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: leadsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: Text(
                      'Could not load leads. Please try again.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  data: (leads) {
                    if (leads.isEmpty) {
                      return const Center(child: Text('No leads yet.'));
                    }
                    return ListView.separated(
                      itemCount: leads.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        color: AppColors.borderSubtle,
                      ),
                      itemBuilder: (context, index) =>
                          _LeadRow(lead: leads[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadRow extends StatelessWidget {
  const _LeadRow({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = [
      lead.companyName,
      lead.leadSource,
      lead.country,
    ].whereType<String>().where((s) => s.isNotEmpty).toList();

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LeadEditorPage(existingLead: lead),
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
                  Row(
                    children: [
                      Text(
                        lead.fullName,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (lead.isArchived) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Archived',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitleParts.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitleParts.join(' · '),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (lead.serviceInterested != null &&
                lead.serviceInterested!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  lead.serviceInterested!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              lead.leadDate,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
