/// Raw values matching the backend's TaskStatus enum.
class TaskStatus {
  static const todo = 'todo';
  static const inProgress = 'in_progress';
  static const pending = 'pending';
  static const completed = 'completed';
  static const cancelled = 'cancelled';

  static const values = [todo, inProgress, pending, completed, cancelled];
}
