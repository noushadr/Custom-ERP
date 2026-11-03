/** One uploaded file of a Knowledge Base article, as saved in the article's
 * (and each version's) `files` list. */
export interface KnowledgeBaseStoredFile {
  /** The name the file had when uploaded (shown to readers). */
  fileName: string;
  /** Server-generated UUID name under the private KB storage folder —
   * never a user-supplied path. */
  storedFileName: string;
  mimeType: string;
  sizeBytes: number;
}
