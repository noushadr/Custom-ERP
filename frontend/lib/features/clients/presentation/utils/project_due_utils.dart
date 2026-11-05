import '../../domain/entities/project.dart';
import '../../domain/entities/project_status.dart';
import '../../domain/entities/project_type.dart';

/// How many days ahead counts as "near" for a deadline or renewal.
const projectDueSoonDays = 14;

/// The values of the Projects page's "Due" filter.
class ProjectDueFilter {
  static const dueSoon = 'due_soon';
  static const overdue = 'overdue';
  static const noDate = 'no_date';

  static const values = [dueSoon, overdue, noDate];

  static String label(String value) => switch (value) {
    dueSoon => 'Near deadline (next $projectDueSoonDays days)',
    overdue => 'Deadline passed',
    noDate => 'No deadline / renewal set',
    _ => value,
  };
}

/// The date that matters for this project: a one-time project's deadline, a
/// retainer's next renewal. Null when it hasn't been set (older projects).
DateTime? projectDueDate(Project project) {
  final iso = project.type == ProjectType.retainer
      ? project.renewalDate
      : project.endDate;
  return iso == null ? null : DateTime.tryParse(iso);
}

/// Projects that are still running — only these can be "due soon" or
/// "overdue"; a completed or cancelled project has nothing left to chase.
bool isOpenProject(Project project) =>
    project.status == ProjectStatus.active ||
    project.status == ProjectStatus.onHold;

bool matchesDueFilter(Project project, String filter, DateTime today) {
  final due = projectDueDate(project);
  final startOfToday = DateTime(today.year, today.month, today.day);
  switch (filter) {
    case ProjectDueFilter.noDate:
      return isOpenProject(project) && due == null;
    case ProjectDueFilter.overdue:
      return isOpenProject(project) &&
          due != null &&
          due.isBefore(startOfToday);
    case ProjectDueFilter.dueSoon:
      if (!isOpenProject(project) || due == null) return false;
      final limit = startOfToday.add(const Duration(days: projectDueSoonDays));
      return !due.isBefore(startOfToday) && !due.isAfter(limit);
  }
  return true;
}
