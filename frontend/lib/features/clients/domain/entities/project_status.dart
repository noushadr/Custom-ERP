/// Raw values matching the backend's ProjectStatus enum.
class ProjectStatus {
  static const active = 'active';
  static const onHold = 'on_hold';
  static const completed = 'completed';
  static const cancelled = 'cancelled';

  static const values = [active, onHold, completed, cancelled];
}
