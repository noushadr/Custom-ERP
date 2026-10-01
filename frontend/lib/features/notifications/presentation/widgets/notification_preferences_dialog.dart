import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/notifications_providers.dart';

/// Lets the viewer mute specific notification categories (e.g. task deadline
/// reminders) while keeping others (e.g. leave approvals) — opened from a
/// settings icon next to the notification bell.
class NotificationPreferencesDialog extends ConsumerWidget {
  const NotificationPreferencesDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(notificationMutePreferencesProvider);

    return AlertDialog(
      title: const Text('Notification preferences'),
      content: SizedBox(
        width: 420,
        child: preferencesAsync.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SizedBox(
            height: 80,
            child: Center(
              child: Text('Could not load preferences: $error'),
            ),
          ),
          data: (preferences) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final preference in preferences)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(preference.label),
                    value: !preference.muted,
                    onChanged: (enabled) async {
                      await ref
                          .read(notificationsRepositoryProvider)
                          .setMutePreference(preference.category, !enabled);
                      ref.invalidate(notificationMutePreferencesProvider);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
