import 'package:zera_erp/features/search/domain/entities/search_result.dart';
import 'package:zera_erp/features/search/domain/repositories/search_repository.dart';

class FakeSearchRepository implements SearchRepository {
  FakeSearchRepository({this.results, this.error});

  final SearchResults? results;
  final Object? error;

  String? lastQuery;

  @override
  Future<SearchResults> search(String query) async {
    lastQuery = query;
    if (error != null) throw error!;
    return results ?? const SearchResults.empty();
  }
}
