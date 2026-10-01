import '../entities/search_result.dart';

abstract interface class SearchRepository {
  Future<SearchResults> search(String query);
}
