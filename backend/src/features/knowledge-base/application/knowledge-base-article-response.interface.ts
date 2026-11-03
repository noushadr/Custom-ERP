/** Describes one uploaded file. */
export interface KnowledgeBaseFileInfoDto {
  fileName: string;
  fileMimeType: string;
  fileSizeBytes: number;
}

export interface KnowledgeBaseArticleSummaryDto {
  id: string;
  title: string;
  /** 'rich_text' (written in the editor) or 'file' (uploaded). */
  contentKind: string;
  /** The uploaded files, in order; empty for a written article. */
  files: KnowledgeBaseFileInfoDto[];
  visibilityType: string;
  /** Who can read it, by name — empty arrays mean "everyone" or that kind
   * of targeting isn't used. */
  targetRoleNames: string[];
  targetDepartmentNames: string[];
  authorName: string;
  lastEditedByName: string;
  versionNumber: number;
  isArchived: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface KnowledgeBaseArticleResponseDto
  extends KnowledgeBaseArticleSummaryDto {
  content: unknown;
  targetRoleIds: string[];
  targetDepartmentIds: string[];
}

export interface KnowledgeBaseArticleVersionSummaryDto {
  id: string;
  files: KnowledgeBaseFileInfoDto[];
  versionNumber: number;
  title: string;
  editorName: string;
  createdAt: string;
}

export interface KnowledgeBaseArticleVersionResponseDto
  extends KnowledgeBaseArticleVersionSummaryDto {
  content: unknown;
}
