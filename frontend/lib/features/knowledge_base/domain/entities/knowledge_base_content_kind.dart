/// Raw values matching the backend's KnowledgeBaseContentKind enum — plain
/// strings, same convention as [KnowledgeBaseVisibility]. An article is
/// either written in the in-app editor or an uploaded file, fixed when it is
/// created.
class KnowledgeBaseContentKind {
  static const richText = 'rich_text';
  static const file = 'file';
}
