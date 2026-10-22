/** How an article's body is provided: written in the in-app rich-text editor,
 * or uploaded as a file (PDF, Word, Excel, PowerPoint, image...). Fixed when
 * the article is created — an article never switches kind afterwards. */
export enum KnowledgeBaseContentKind {
  RICH_TEXT = 'rich_text',
  FILE = 'file',
}
