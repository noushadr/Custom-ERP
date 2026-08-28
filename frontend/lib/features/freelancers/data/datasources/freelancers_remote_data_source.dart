import 'package:dio/dio.dart';
import '../models/freelancer_model.dart';

class FreelancersRemoteDataSource {
  const FreelancersRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<FreelancerModel>> getFreelancers({bool activeOnly = false}) async {
    final response = await _dio.get<List<dynamic>>(
      '/freelancers',
      queryParameters: {'activeOnly': activeOnly.toString()},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(FreelancerModel.fromJson)
        .toList();
  }

  Future<FreelancerModel> createFreelancer({
    required String fullName,
    String? role,
    String? notes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/freelancers',
      data: {'fullName': fullName, 'role': ?role, 'notes': ?notes},
    );
    return FreelancerModel.fromJson(response.data!);
  }

  Future<FreelancerModel> updateFreelancer(
    String id, {
    String? fullName,
    String? role,
    String? notes,
    bool? isActive,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/freelancers/$id',
      data: {
        'fullName': ?fullName,
        'role': ?role,
        'notes': ?notes,
        'isActive': ?isActive,
      },
    );
    return FreelancerModel.fromJson(response.data!);
  }
}
