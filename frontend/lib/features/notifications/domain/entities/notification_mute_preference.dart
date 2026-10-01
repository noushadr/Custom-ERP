/// One known notification category plus whether the viewer has muted it —
/// the full known-category list always comes back from the backend
/// (`GET /notifications/mute-preferences`), so there's no separate "all
/// categories" enum to keep in sync on this side.
class NotificationMutePreference {
  const NotificationMutePreference({
    required this.category,
    required this.label,
    required this.muted,
  });

  final String category;
  final String label;
  final bool muted;
}
