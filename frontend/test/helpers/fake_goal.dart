import 'package:zera_erp/features/goals/domain/entities/goal.dart';
import 'package:zera_erp/features/goals/domain/repositories/goal_repository.dart';

Goal buildTestGoal({
  String id = 'goal-1',
  String employeeId = 'employee-1',
  String employeeName = 'Babar Hussain',
  String? employeePhotoUrl,
  String? departmentId,
  String? departmentName,
  String title = 'English speaking',
  String? description,
  int achievementPercentage = 0,
  String createdByName = 'Noushad Ranani',
  DateTime? createdAt,
}) {
  return Goal(
    id: id,
    employeeId: employeeId,
    employeeName: employeeName,
    employeePhotoUrl: employeePhotoUrl,
    departmentId: departmentId,
    departmentName: departmentName,
    title: title,
    description: description,
    achievementPercentage: achievementPercentage,
    createdByName: createdByName,
    createdAt: createdAt ?? DateTime(2026, 9, 8),
  );
}

class FakeGoalRepository implements GoalRepository {
  FakeGoalRepository({
    this.all = const [],
    this.mine = const [],
    this.team = const [],
    this.actionError,
  });

  final List<Goal> all;
  final List<Goal> mine;
  final List<Goal> team;
  final Object? actionError;

  String? lastCreatedEmployeeId;
  String? lastCreatedTitle;
  String? lastBulkDepartmentId;
  String? lastBulkTitle;
  String? lastUpdatedGoalId;
  int? lastUpdatedAchievementPercentage;
  String? lastArchivedGoalId;
  bool? lastActionWasManagerScoped;

  @override
  Future<List<Goal>> getAll() async => all;

  @override
  Future<List<Goal>> getMine() async => mine;

  @override
  Future<List<Goal>> getTeam() async => team;

  @override
  Future<Goal> createForEmployee({
    required String employeeId,
    required String title,
    String? description,
  }) async {
    lastCreatedEmployeeId = employeeId;
    lastCreatedTitle = title;
    lastActionWasManagerScoped = false;
    if (actionError != null) throw actionError!;
    return buildTestGoal(employeeId: employeeId, title: title);
  }

  @override
  Future<Goal> createForMyDirectReport({
    required String employeeId,
    required String title,
    String? description,
  }) async {
    lastCreatedEmployeeId = employeeId;
    lastCreatedTitle = title;
    lastActionWasManagerScoped = true;
    if (actionError != null) throw actionError!;
    return buildTestGoal(employeeId: employeeId, title: title);
  }

  @override
  Future<List<Goal>> bulkAssignToDepartment({
    required String departmentId,
    required String title,
    String? description,
  }) async {
    lastBulkDepartmentId = departmentId;
    lastBulkTitle = title;
    if (actionError != null) throw actionError!;
    return [buildTestGoal(title: title)];
  }

  @override
  Future<Goal> update(
    String goalId, {
    String? title,
    String? description,
    int? achievementPercentage,
  }) async {
    lastUpdatedGoalId = goalId;
    lastUpdatedAchievementPercentage = achievementPercentage;
    lastActionWasManagerScoped = false;
    if (actionError != null) throw actionError!;
    return buildTestGoal(
      id: goalId,
      title: title ?? 'English speaking',
      achievementPercentage: achievementPercentage ?? 0,
    );
  }

  @override
  Future<Goal> updateAsManager(
    String goalId, {
    String? title,
    String? description,
  }) async {
    lastUpdatedGoalId = goalId;
    lastActionWasManagerScoped = true;
    if (actionError != null) throw actionError!;
    return buildTestGoal(id: goalId, title: title ?? 'English speaking');
  }

  @override
  Future<void> archive(String goalId) async {
    lastArchivedGoalId = goalId;
    lastActionWasManagerScoped = false;
    if (actionError != null) throw actionError!;
  }

  @override
  Future<void> archiveAsManager(String goalId) async {
    lastArchivedGoalId = goalId;
    lastActionWasManagerScoped = true;
    if (actionError != null) throw actionError!;
  }
}
