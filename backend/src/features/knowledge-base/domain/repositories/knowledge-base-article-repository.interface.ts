import { KnowledgeBaseArticle } from '../entities/knowledge-base-article.entity';

export const KNOWLEDGE_BASE_ARTICLE_REPOSITORY = Symbol(
  'KNOWLEDGE_BASE_ARTICLE_REPOSITORY',
);

export interface KnowledgeBaseArticleRepository {
  findAll(includeArchived?: boolean): Promise<KnowledgeBaseArticle[]>;
  findById(id: string): Promise<KnowledgeBaseArticle | null>;
  save(article: KnowledgeBaseArticle): Promise<KnowledgeBaseArticle>;
}
