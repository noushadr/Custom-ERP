import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/search_remote_data_source.dart';
import '../data/repositories/search_repository_impl.dart';
import '../domain/entities/search_result.dart';
import '../domain/repositories/search_repository.dart';

final searchRemoteDataSourceProvider = Provider<SearchRemoteDataSource>(
  (ref) => SearchRemoteDataSource(ref.watch(dioClientProvider).dio),
);

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepositoryImpl(ref.watch(searchRemoteDataSourceProvider)),
);

/// Keyed by the search query — the dialog that owns this keeps its own
/// debounce timer and only updates the watched query once the viewer has
/// paused typing, so this doesn't fire a request per keystroke.
final searchResultsProvider = FutureProvider.autoDispose
    .family<SearchResults, String>((ref, query) {
      if (query.trim().length < 2) return const SearchResults.empty();
      return ref.watch(searchRepositoryProvider).search(query);
    });
