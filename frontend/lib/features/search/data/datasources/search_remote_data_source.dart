import 'package:dio/dio.dart';
import '../models/search_result_model.dart';

class SearchRemoteDataSource {
  const SearchRemoteDataSource(this._dio);

  final Dio _dio;

  Future<SearchResultsModel> search(String query) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/search',
      queryParameters: {'q': query},
    );
    return SearchResultsModel.fromJson(response.data!);
  }
}
