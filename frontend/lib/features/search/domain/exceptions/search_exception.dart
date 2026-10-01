class SearchException implements Exception {
  const SearchException(this.message);

  final String message;

  @override
  String toString() => message;
}
