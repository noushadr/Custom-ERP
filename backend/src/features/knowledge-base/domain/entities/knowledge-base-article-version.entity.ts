import type { KnowledgeBaseStoredFile } from './knowledge-base-stored-file';
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

  /** The files this version pointed at, for versions of a FILE article
   * (empty for written ones). Replaced files stay on disk so an old version
   * can still be opened from the history. */
  @Column({ type: 'jsonb', default: () => "'[]'" })
  files: KnowledgeBaseStoredFile[];

  @Column()
  editorUserId: string;

  @Column()
  editorName: string;
}
