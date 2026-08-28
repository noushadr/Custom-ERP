export interface KnowledgeBaseArticleSummaryDto {
  id: string;
  title: string;
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

export interface KnowledgeBaseArticleVersionSummaryDto {
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
