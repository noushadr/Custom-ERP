import 'package:dio/dio.dart';

class ModuleLockRemoteDataSource {
  const ModuleLockRemoteDataSource(this._dio);

  final Dio _dio;

  Future<bool> verifyPin(String pin) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/module-locks/verify',
      data: {'pin': pin},
    );
    return response.data!['valid'] as bool;
  }
}
