import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { KnowledgeBaseArticle } from './knowledge-base-article.entity';

/** An immutable snapshot of an article's title+content at the moment of a
 * content-changing edit — never mutated once written. Ordered by
 * versionNumber to form the "previous versions, who changed them" history
 * the article itself doesn't need to carry. */
@Entity('knowledge_base_article_versions')
export class KnowledgeBaseArticleVersion extends BaseEntity {
  @Column()
  articleId: string;

  @ManyToOne(() => KnowledgeBaseArticle, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'articleId' })
  article: KnowledgeBaseArticle;

  @Column({ type: 'int' })
  versionNumber: number;

  @Column()
  title: string;

  @Column({ type: 'jsonb' })
  content: unknown;

  @Column()
  editorUserId: string;

  @Column()
  editorName: string;
}
