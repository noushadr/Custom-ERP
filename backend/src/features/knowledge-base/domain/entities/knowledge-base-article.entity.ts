import { Column, Entity, JoinTable, ManyToMany } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Department } from '../../../departments/domain/entities/department.entity';
import { Role } from '../../../authentication/domain/entities/role.entity';
import { KnowledgeBaseContentKind } from '../enums/knowledge-base-content-kind.enum';
import { KnowledgeBaseVisibility } from '../enums/knowledge-base-visibility.enum';

/** The current, live state of a Knowledge Base article. Every edit that
 * changes `title`/`content` also inserts a KnowledgeBaseArticleVersion
 * snapshot (see that entity) — this row always reflects the latest one, so
 * reading an article never needs a join into its own history. */
@Entity('knowledge_base_articles')
export class KnowledgeBaseArticle extends BaseEntity {
  @Column()
  title: string;

  /** The current content as a Quill Delta (rich-text ops), stored verbatim
   * — the frontend editor/viewer round-trips this without any backend-side
   * interpretation of its structure. */
  @Column({ type: 'jsonb' })
  content: unknown;

  /** Written in the rich-text editor, or an uploaded file. Fixed at creation.
   * For a FILE article `content` is just an empty Delta and the `file*`
   * columns below describe the upload. */
  @Column({
    type: 'enum',
    enum: KnowledgeBaseContentKind,
    enumName: 'knowledge_base_content_kind_enum',
    default: KnowledgeBaseContentKind.RICH_TEXT,
  })
  contentKind: KnowledgeBaseContentKind;

  /** The name the uploaded file had (shown to readers and used for the
   * download). Null for written articles. */
  @Column({ type: 'varchar', nullable: true })
  fileName: string | null;

  /** Server-generated UUID file name under the private KB storage folder —
   * never a user-supplied path. */
  @Column({ type: 'varchar', nullable: true })
  storedFileName: string | null;

  @Column({ type: 'varchar', nullable: true })
  fileMimeType: string | null;

  @Column({ type: 'int', nullable: true })
  fileSizeBytes: number | null;

  @Column({ type: 'enum', enum: KnowledgeBaseVisibility })
  visibilityType: KnowledgeBaseVisibility;

  @ManyToMany(() => Role, { eager: true })
  @JoinTable({
    name: 'knowledge_base_article_target_roles',
    joinColumn: { name: 'articleId', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'roleId', referencedColumnName: 'id' },
  })
  targetRoles: Role[];

  @ManyToMany(() => Department, { eager: true })
  @JoinTable({
    name: 'knowledge_base_article_target_departments',
    joinColumn: { name: 'articleId', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'departmentId', referencedColumnName: 'id' },
  })
  targetDepartments: Department[];

  @Column()
  authorUserId: string;

  @Column()
  authorName: string;

  @Column()
  lastEditedByUserId: string;

  @Column()
  lastEditedByName: string;

  @Column({ type: 'int', default: 1 })
  versionNumber: number;

  /** Soft-unpublish — same convention as LeaveType/ChecklistTemplateItem/
   * PerformanceReviewCriterion, so a retired article's version history
   * still exists rather than being destroyed. */
  @Column({ default: false })
  isArchived: boolean;
}
