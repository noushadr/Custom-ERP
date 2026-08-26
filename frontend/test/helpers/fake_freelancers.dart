import 'package:zera_erp/features/freelancers/domain/entities/freelancer.dart';
import 'package:zera_erp/features/freelancers/domain/repositories/freelancers_repository.dart';

Freelancer buildTestFreelancer({
  String id = 'freelancer-1',
  String fullName = 'Kulsum Zehra',
  String? role = 'Content Writer',
  String? notes,
  bool isActive = true,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Freelancer(
    id: id,
    fullName: fullName,
    role: role,
    notes: notes,
    isActive: isActive,
    createdAt: createdAt ?? DateTime(2026, 8, 1),
    updatedAt: updatedAt ?? DateTime(2026, 8, 1),
  );
}

class FakeFreelancersRepository implements FreelancersRepository {
  FakeFreelancersRepository({List<Freelancer>? freelancers})
    : freelancers = freelancers ?? [buildTestFreelancer()];

  final List<Freelancer> freelancers;

  String? lastCreatedFullName;
  String? lastCreatedRole;

  String? lastUpdatedId;
  String? lastUpdatedFullName;
  String? lastUpdatedRole;
  bool? lastUpdatedIsActive;

  @override
  Future<List<Freelancer>> getFreelancers({bool activeOnly = false}) async =>
      activeOnly ? freelancers.where((f) => f.isActive).toList() : freelancers;

  @override
  Future<Freelancer> createFreelancer({
    required String fullName,
    String? role,
    String? notes,
  }) async {
    lastCreatedFullName = fullName;
    lastCreatedRole = role;
    return buildTestFreelancer(fullName: fullName, role: role, notes: notes);
  }

  @override
  Future<Freelancer> updateFreelancer(
    String id, {
    String? fullName,
    String? role,
    String? notes,
    bool? isActive,
  }) async {
    lastUpdatedId = id;
    lastUpdatedFullName = fullName;
    lastUpdatedRole = role;
    lastUpdatedIsActive = isActive;
    return buildTestFreelancer(
      id: id,
      fullName: fullName ?? 'Kulsum Zehra',
      role: role,
      notes: notes,
      isActive: isActive ?? true,
    );
  }
}
