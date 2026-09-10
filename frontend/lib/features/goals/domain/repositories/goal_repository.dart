import '../entities/goal.dart';

abstract interface class GoalRepository {
  /// Every goal company-wide. Requires `goals.manage`.
  Future<List<Goal>> getAll();

  /// The caller's own goals — for their own dashboard.
  Future<List<Goal>> getMine();

  /// Goals belonging to the caller's own direct reports.
  Future<List<Goal>> getTeam();

  /// Requires `goals.manage`.
  Future<Goal> createForEmployee({
    required String employeeId,
    required String title,
    String? description,
  });

  /// A Team Lead setting a goal for one of their own direct reports.
  Future<Goal> createForMyDirectReport({
    required String employeeId,
    required String title,
    String? description,
  });

  /// Creates the same goal for every active employee in [departmentId].
  /// Requires `goals.manage`.
  Future<List<Goal>> bulkAssignToDepartment({
    required String departmentId,
    required String title,
    String? description,
  });

  /// Requires `goals.manage`. [achievementPercentage] (0-100) is also
  /// Admin/HR only — pass it through `updateAsManager` and it's ignored.
  Future<Goal> update(
    String goalId, {
    String? title,
    String? description,
    int? achievementPercentage,
  });

  /// A Team Lead editing a goal belonging to one of their own direct
  /// reports — no [achievementPercentage] param; that's Admin/HR only.
  Future<Goal> updateAsManager(
    String goalId, {
    String? title,
    String? description,
  });

  /// Soft-hides the goal rather than deleting it. Requires `goals.manage`.
  Future<void> archive(String goalId);

  /// A Team Lead archiving a goal belonging to one of their own direct
  /// reports.
  Future<void> archiveAsManager(String goalId);
}
