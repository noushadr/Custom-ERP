import '../entities/freelancer.dart';

abstract interface class FreelancersRepository {
  Future<List<Freelancer>> getFreelancers({bool activeOnly = false});
  Future<Freelancer> createFreelancer({
    required String fullName,
    String? role,
    String? notes,
  });
  Future<Freelancer> updateFreelancer(
    String id, {
    String? fullName,
    String? role,
    String? notes,
    bool? isActive,
  });
}
