/** Describes an uploaded file; all null for a written (rich-text) article. */
export interface KnowledgeBaseFileInfoDto {
  fileName: string | null;
  fileMimeType: string | null;
  fileSizeBytes: number | null;
}

export interface KnowledgeBaseArticleSummaryDto extends KnowledgeBaseFileInfoDto {
  id: string;
  title: string;
  /** 'rich_text' (written in the editor) or 'file' (uploaded). */
  contentKind: string;
  visibilityType: string;
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

export interface KnowledgeBaseArticleVersionSummaryDto
  extends KnowledgeBaseFileInfoDto {
  id: string;
  versionNumber: number;
  title: string;
  editorName: string;
  createdAt: string;
}

export interface KnowledgeBaseArticleVersionResponseDto
  extends KnowledgeBaseArticleVersionSummaryDto {
  content: unknown;
}
