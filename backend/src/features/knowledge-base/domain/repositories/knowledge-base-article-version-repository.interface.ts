import { KnowledgeBaseArticleVersion } from '../entities/knowledge-base-article-version.entity';

export const KNOWLEDGE_BASE_ARTICLE_VERSION_REPOSITORY = Symbol(
  'KNOWLEDGE_BASE_ARTICLE_VERSION_REPOSITORY',
);

export interface KnowledgeBaseArticleVersionRepository {
  findByArticleId(articleId: string): Promise<KnowledgeBaseArticleVersion[]>;
  findById(id: string): Promise<KnowledgeBaseArticleVersion | null>;
  save(
    version: KnowledgeBaseArticleVersion,
  ): Promise<KnowledgeBaseArticleVersion>;
}
