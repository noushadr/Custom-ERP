import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/currency_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../employee/presentation/widgets/employee_status_badges.dart';
import '../../application/clients_providers.dart';
import '../../domain/entities/client.dart';
import '../widgets/project_badges.dart';
import 'client_editor_page.dart';
import 'project_detail_page.dart';

class ClientDetailPage extends ConsumerWidget {
  const ClientDetailPage({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientProvider(clientId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client'),
        actions: [
          clientAsync.maybeWhen(
            data: (client) => TextButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ClientEditorPage(existingClient: client),
                  ),
                );
                ref.invalidate(clientProvider(clientId));
                ref.invalidate(clientsListProvider(false));
                ref.invalidate(clientsListProvider(true));
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: clientAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Could not load this client.'),
            ),
            data: (client) => _ClientDetailBody(client: client),
          ),
        ),
      ),
    );
  }
}

class _ClientDetailBody extends ConsumerWidget {
  const _ClientDetailBody({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(
      projectsListProvider((status: null, clientId: client.id)),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  client.companyName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (client.isArchived)
                const StatusBadge(label: 'Archived', color: AppColors.error),
            ],
          ),
          if (client.industry != null) ...[
            const SizedBox(height: 4),
            Text(
              client.industry!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 16),
          FormSection(
            title: 'Contact',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (client.primaryContactName != null)
                  Text('Contact: ${client.primaryContactName}'),
                if (client.primaryContactEmail != null)
                  Text('Email: ${client.primaryContactEmail}'),
                if (client.primaryContactPhone != null)
                  Text('Phone: ${client.primaryContactPhone}'),
                if (client.website != null) Text('Website: ${client.website}'),
                if (client.address != null) Text('Address: ${client.address}'),
                if (client.primaryContactName == null &&
                    client.primaryContactEmail == null &&
                    client.primaryContactPhone == null &&
                    client.website == null &&
                    client.address == null)
                  Text(
                    'No contact details yet.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (client.notes != null && client.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            FormSection(title: 'Notes', child: Text(client.notes!)),
          ],
          const SizedBox(height: 16),
          FormSection(
            title: 'Projects',
            child: projectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('Could not load projects.'),
              data: (projects) => projects.isEmpty
                  ? Text(
                      'No projects for this client yet.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < projects.length; i++) ...[
                          InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProjectDetailPage(
                                  projectId: projects[i].id,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      projects[i].name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ),
                                  ProjectStatusBadge(
                                    status: projects[i].status,
                                    dense: true,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'PKR ${formatWholeAmount(projects[i].netPrice)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (i < projects.length - 1)
                            const Divider(
                              height: 1,
                              color: AppColors.borderSubtle,
                            ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
