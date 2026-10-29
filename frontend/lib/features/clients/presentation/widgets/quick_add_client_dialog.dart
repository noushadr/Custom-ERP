import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../application/clients_providers.dart';
import '../../domain/entities/client.dart';
import '../../domain/exceptions/client_exception.dart';

/// A minimal "new client" dialog — just the company/client name, which is
/// the only field `createClient` actually requires; the full client form in
/// Clients & Projects still covers everything else (industry, website,
/// primary contact, ...) for later.
Future<Client?> showQuickAddClientDialog(
  BuildContext context,
  WidgetRef ref, {
  String initialName = '',
}) {
  final nameController = TextEditingController(text: initialName);
  var submitting = false;
  String? error;

  return showAppDialog<Client>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: const Text('New client'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (error != null) ...[
                Text(
                  error!,
                  style: TextStyle(
                    color: Theme.of(dialogContext).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Client / Company name',
                ),
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: submitting
                ? null
                : () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: submitting
                ? null
                : () async {
                    final name = nameController.text.trim();
                    if (name.length < 2) {
                      setState(() => error = 'Enter a client name.');
                      return;
                    }
                    setState(() {
                      submitting = true;
                      error = null;
                    });
                    try {
                      final client = await ref
                          .read(clientsRepositoryProvider)
                          .createClient(companyName: name);
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(client);
                      }
                    } on ClientException catch (e) {
                      setState(() {
                        submitting = false;
                        error = e.message;
                      });
                    }
                  },
            child: submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
    ),
  );
}
