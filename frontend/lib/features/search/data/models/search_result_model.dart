import '../../domain/entities/search_result.dart';

class SearchResultsModel extends SearchResults {
  const SearchResultsModel({
    required super.employees,
    required super.tasks,
    required super.projects,
    required super.clients,
    required super.articles,
    required super.leads,
  });

  factory SearchResultsModel.fromJson(Map<String, dynamic> json) =>
      SearchResultsModel(
        employees: _itemsFrom(json['employees'], SearchResultType.employee),
        tasks: _itemsFrom(json['tasks'], SearchResultType.task),
        projects: _itemsFrom(json['projects'], SearchResultType.project),
        clients: _itemsFrom(json['clients'], SearchResultType.client),
        articles: _itemsFrom(json['articles'], SearchResultType.article),
        leads: _itemsFrom(json['leads'], SearchResultType.lead),
      );

  static List<SearchResultItem> _itemsFrom(
    dynamic json,
    SearchResultType type,
  ) => (json as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map(
        (item) => SearchResultItem(
          id: item['id'] as String,
          title: item['title'] as String,
          subtitle: item['subtitle'] as String?,
          type: type,
        ),
      )
      .toList();
}
