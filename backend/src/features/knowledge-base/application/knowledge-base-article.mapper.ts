import { KnowledgeBaseArticleVersion } from '../domain/entities/knowledge-base-article-version.entity';
import { KnowledgeBaseArticle } from '../domain/entities/knowledge-base-article.entity';
import {
  KnowledgeBaseArticleResponseDto,
  KnowledgeBaseArticleSummaryDto,
  KnowledgeBaseArticleVersionResponseDto,
  KnowledgeBaseArticleVersionSummaryDto,
} from './knowledge-base-article-response.interface';

/** Flattens to a DTO before returning from a controller — same convention as
 * toPerformanceReviewResponse/toRequestResponse — decoupling the response
 * shape from the entity (e.g. targetRoles/targetDepartments collapse to
 * plain id arrays rather than leaking full Role/Department entities). */
export function toKnowledgeBaseArticleSummary(
  article: KnowledgeBaseArticle,
): KnowledgeBaseArticleSummaryDto {
  return {
    id: article.id,
    title: article.title,
    visibilityType: article.visibilityType,
    authorName: article.authorName,
    lastEditedByName: article.lastEditedByName,
    versionNumber: article.versionNumber,
    isArchived: article.isArchived,
    createdAt: article.createdAt.toISOString(),
    updatedAt: article.updatedAt.toISOString(),
  };
}

export function toKnowledgeBaseArticleResponse(
  article: KnowledgeBaseArticle,
): KnowledgeBaseArticleResponseDto {
  return {
    ...toKnowledgeBaseArticleSummary(article),
    content: article.content,
    targetRoleIds: article.targetRoles.map((role) => role.id),
    targetDepartmentIds: article.targetDepartments.map((dept) => dept.id),
  };
}

export function toKnowledgeBaseArticleVersionSummary(
  version: KnowledgeBaseArticleVersion,
): KnowledgeBaseArticleVersionSummaryDto {
  return {
    id: version.id,
    versionNumber: version.versionNumber,
    title: version.title,
    editorName: version.editorName,
    createdAt: version.createdAt.toISOString(),
  };
}

export function toKnowledgeBaseArticleVersionResponse(
  version: KnowledgeBaseArticleVersion,
): KnowledgeBaseArticleVersionResponseDto {
  return {
    ...toKnowledgeBaseArticleVersionSummary(version),
    content: version.content,
  };
}
