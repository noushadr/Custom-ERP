/// What kind of record a [SearchResultItem] points at — drives both the icon
/// shown next to it and which detail page tapping it opens.
enum SearchResultType { employee, task, project, client, article, lead }

class SearchResultItem {
  const SearchResultItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
  });

  final String id;
  final String title;
  final String? subtitle;
  final SearchResultType type;
}

/// One category per record type the viewer's own permissions unlock — a
/// category the viewer can't search (e.g. Leads without `leads.manage`)
/// simply comes back as an empty list, same as the backend never querying
/// it at all.
class SearchResults {
  const SearchResults({
    required this.employees,
    required this.tasks,
    required this.projects,
    required this.clients,
    required this.articles,
    required this.leads,
  });

  const SearchResults.empty()
    : employees = const [],
      tasks = const [],
      projects = const [],
      clients = const [],
      articles = const [],
      leads = const [];

  final List<SearchResultItem> employees;
  final List<SearchResultItem> tasks;
  final List<SearchResultItem> projects;
  final List<SearchResultItem> clients;
  final List<SearchResultItem> articles;
  final List<SearchResultItem> leads;

  bool get isEmpty =>
      employees.isEmpty &&
      tasks.isEmpty &&
      projects.isEmpty &&
      clients.isEmpty &&
      articles.isEmpty &&
      leads.isEmpty;
}
