import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { resolveActorName } from '../../../core/utils/resolve-actor-name.util';
import {
  USER_REPOSITORY,
  type UserRepository,
} from '../../authentication/domain/repositories/user-repository.interface';
import {
  ROLE_REPOSITORY,
  type RoleRepository,
} from '../../authentication/domain/repositories/role-repository.interface';
import { Role } from '../../authentication/domain/entities/role.entity';
import {
  DEPARTMENT_REPOSITORY,
  type DepartmentRepository,
} from '../../departments/domain/repositories/department-repository.interface';
import { Department } from '../../departments/domain/entities/department.entity';
import {
  EMPLOYEE_REPOSITORY,
  type EmployeeRepository,
} from '../../employee/domain/repositories/employee-repository.interface';
import { CreateKnowledgeBaseArticleDto } from './dto/create-knowledge-base-article.dto';
import { UpdateKnowledgeBaseArticleDto } from './dto/update-knowledge-base-article.dto';
import {
  KnowledgeBaseArticleResponseDto,
  KnowledgeBaseArticleSummaryDto,
  KnowledgeBaseArticleVersionResponseDto,
  KnowledgeBaseArticleVersionSummaryDto,
} from './knowledge-base-article-response.interface';
import {
  toKnowledgeBaseArticleResponse,
  toKnowledgeBaseArticleSummary,
  toKnowledgeBaseArticleVersionResponse,
  toKnowledgeBaseArticleVersionSummary,
} from './knowledge-base-article.mapper';
import { KnowledgeBaseArticleVersion } from '../domain/entities/knowledge-base-article-version.entity';
import { KnowledgeBaseArticle } from '../domain/entities/knowledge-base-article.entity';
import { KnowledgeBaseVisibility } from '../domain/enums/knowledge-base-visibility.enum';
import {
  KNOWLEDGE_BASE_ARTICLE_REPOSITORY,
  type KnowledgeBaseArticleRepository,
} from '../domain/repositories/knowledge-base-article-repository.interface';
import {
  KNOWLEDGE_BASE_ARTICLE_VERSION_REPOSITORY,
  type KnowledgeBaseArticleVersionRepository,
} from '../domain/repositories/knowledge-base-article-version-repository.interface';

interface Viewer {
  roleName: string | null;
  departmentId: string | null;
}

@Injectable()
export class KnowledgeBaseService {
  constructor(
    @Inject(KNOWLEDGE_BASE_ARTICLE_REPOSITORY)
    private readonly articleRepository: KnowledgeBaseArticleRepository,
    @Inject(KNOWLEDGE_BASE_ARTICLE_VERSION_REPOSITORY)
    private readonly versionRepository: KnowledgeBaseArticleVersionRepository,
    @Inject(EMPLOYEE_REPOSITORY)
    private readonly employeeRepository: EmployeeRepository,
    @Inject(USER_REPOSITORY)
    private readonly userRepository: UserRepository,
    @Inject(ROLE_REPOSITORY)
    private readonly roleRepository: RoleRepository,
    @Inject(DEPARTMENT_REPOSITORY)
    private readonly departmentRepository: DepartmentRepository,
  ) {}

  // ---- Reads, filtered by visibility ----

  async getVisibleArticles(
    actorUserId: string,
    actorHasOverride: boolean,
    includeArchived: boolean,
  ): Promise<KnowledgeBaseArticleSummaryDto[]> {
    const articles = await this.articleRepository.findAll(
      actorHasOverride && includeArchived,
    );
    if (actorHasOverride) return articles.map(toKnowledgeBaseArticleSummary);

    const viewer = await this.resolveViewer(actorUserId);
    return articles
      .filter((article) => this.isVisibleTo(article, viewer))
      .map(toKnowledgeBaseArticleSummary);
  }

  /** Visible to the article's own employee, their reporting manager, or a
   * `knowledge_base.manage` holder — never to an arbitrary authenticated
   * user who happens to know the id. */
  async getArticleForActor(
    id: string,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<KnowledgeBaseArticleResponseDto> {
    const article = await this.getArticleOr404(id);
    if (!actorHasOverride) {
      const viewer = await this.resolveViewer(actorUserId);
      if (!this.isVisibleTo(article, viewer)) {
        throw new ForbiddenException(
          'You do not have access to this article',
        );
      }
    }
    return toKnowledgeBaseArticleResponse(article);
  }

  /** Anyone who can view the article can see who changed it and when — not
   * gated further by `knowledge_base.manage`. */
  async getVersionHistory(
    articleId: string,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<KnowledgeBaseArticleVersionSummaryDto[]> {
    await this.getArticleForActor(articleId, actorUserId, actorHasOverride);
    const versions = await this.versionRepository.findByArticleId(articleId);
    return versions.map(toKnowledgeBaseArticleVersionSummary);
  }

  async getVersionForActor(
    articleId: string,
    versionId: string,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<KnowledgeBaseArticleVersionResponseDto> {
    await this.getArticleForActor(articleId, actorUserId, actorHasOverride);
    const version = await this.versionRepository.findById(versionId);
    if (!version || version.articleId !== articleId) {
      throw new NotFoundException('Version not found');
    }
    return toKnowledgeBaseArticleVersionResponse(version);
  }

  // ---- Writes ----

  async createArticle(
    dto: CreateKnowledgeBaseArticleDto,
    actorUserId: string,
  ): Promise<KnowledgeBaseArticleResponseDto> {
    this.validateTargeting(
      dto.visibilityType,
      dto.targetRoleIds,
      dto.targetDepartmentIds,
    );
    const actorName = await resolveActorName(
      this.employeeRepository,
      this.userRepository,
      actorUserId,
    );

    const article = new KnowledgeBaseArticle();
    article.title = dto.title;
    article.content = dto.content;
    article.visibilityType = dto.visibilityType;
    article.targetRoles = await this.resolveTargetRoles(dto.targetRoleIds);
    article.targetDepartments = await this.resolveTargetDepartments(
      dto.targetDepartmentIds,
    );
    article.authorUserId = actorUserId;
    article.authorName = actorName;
    article.lastEditedByUserId = actorUserId;
    article.lastEditedByName = actorName;
    article.versionNumber = 1;
    article.isArchived = false;
    const saved = await this.articleRepository.save(article);

    const version = new KnowledgeBaseArticleVersion();
    version.articleId = saved.id;
    version.versionNumber = 1;
    version.title = saved.title;
    version.content = saved.content;
    version.editorUserId = actorUserId;
    version.editorName = actorName;
    await this.versionRepository.save(version);

    return toKnowledgeBaseArticleResponse(await this.getArticleOr404(saved.id));
  }

  /** A new version snapshot is only inserted when the save actually touches
   * `title`/`content` — a pure visibility/archive toggle updates the
   * article in place, since "version history" means content history, not
   * every metadata tweak. */
  async updateArticle(
    id: string,
    dto: UpdateKnowledgeBaseArticleDto,
    actorUserId: string,
  ): Promise<KnowledgeBaseArticleResponseDto> {
    const article = await this.getArticleOr404(id);

    const visibilityType = dto.visibilityType ?? article.visibilityType;
    const targetRoleIds =
      dto.targetRoleIds ?? article.targetRoles.map((role) => role.id);
    const targetDepartmentIds =
      dto.targetDepartmentIds ??
      article.targetDepartments.map((dept) => dept.id);
    this.validateTargeting(visibilityType, targetRoleIds, targetDepartmentIds);

    const isContentEdit = dto.title !== undefined || dto.content !== undefined;
    const actorName = isContentEdit
      ? await resolveActorName(
          this.employeeRepository,
          this.userRepository,
          actorUserId,
        )
      : null;

    if (dto.title !== undefined) article.title = dto.title;
    if (dto.content !== undefined) article.content = dto.content;
    article.visibilityType = visibilityType;
    if (dto.targetRoleIds !== undefined) {
      article.targetRoles = await this.resolveTargetRoles(dto.targetRoleIds);
    }
    if (dto.targetDepartmentIds !== undefined) {
      article.targetDepartments = await this.resolveTargetDepartments(
        dto.targetDepartmentIds,
      );
    }
    if (dto.isArchived !== undefined) article.isArchived = dto.isArchived;

    if (isContentEdit && actorName) {
      article.versionNumber += 1;
      article.lastEditedByUserId = actorUserId;
      article.lastEditedByName = actorName;
    }

    const saved = await this.articleRepository.save(article);

    if (isContentEdit && actorName) {
      const version = new KnowledgeBaseArticleVersion();
      version.articleId = saved.id;
      version.versionNumber = saved.versionNumber;
      version.title = saved.title;
      version.content = saved.content;
      version.editorUserId = actorUserId;
      version.editorName = actorName;
      await this.versionRepository.save(version);
    }

    return toKnowledgeBaseArticleResponse(await this.getArticleOr404(saved.id));
  }

  // ---- Helpers ----

  private async getArticleOr404(id: string): Promise<KnowledgeBaseArticle> {
    const article = await this.articleRepository.findById(id);
    if (!article) throw new NotFoundException('Article not found');
    return article;
  }

  private async resolveViewer(actorUserId: string): Promise<Viewer> {
    const employee = await this.employeeRepository.findByUserId(actorUserId);
    if (!employee) return { roleName: null, departmentId: null };
    return {
      roleName: employee.user.role.name,
      departmentId: employee.departmentId ?? null,
    };
  }

  /** Union semantics: visible if the viewer matches a targeted role OR a
   * targeted department — not both at once. For `everyone` neither list is
   * populated so this always returns true up-front. */
  private isVisibleTo(article: KnowledgeBaseArticle, viewer: Viewer): boolean {
    if (article.visibilityType === KnowledgeBaseVisibility.EVERYONE) {
      return true;
    }
    const matchesRole =
      viewer.roleName !== null &&
      article.targetRoles.some((role) => role.name === viewer.roleName);
    const matchesDepartment =
      viewer.departmentId !== null &&
      article.targetDepartments.some(
        (dept) => dept.id === viewer.departmentId,
      );
    return matchesRole || matchesDepartment;
  }

  private validateTargeting(
    visibilityType: KnowledgeBaseVisibility,
    targetRoleIds: string[] | undefined,
    targetDepartmentIds: string[] | undefined,
  ): void {
    const needsRoles =
      visibilityType === KnowledgeBaseVisibility.ROLES ||
      visibilityType === KnowledgeBaseVisibility.ROLES_AND_DEPARTMENTS;
    const needsDepartments =
      visibilityType === KnowledgeBaseVisibility.DEPARTMENTS ||
      visibilityType === KnowledgeBaseVisibility.ROLES_AND_DEPARTMENTS;

    if (needsRoles && (!targetRoleIds || targetRoleIds.length === 0)) {
      throw new BadRequestException(
        'Select at least one role for this visibility type',
      );
    }
    if (
      needsDepartments &&
      (!targetDepartmentIds || targetDepartmentIds.length === 0)
    ) {
      throw new BadRequestException(
        'Select at least one department for this visibility type',
      );
    }
  }

  private async resolveTargetRoles(ids: string[] | undefined): Promise<Role[]> {
    if (!ids || ids.length === 0) return [];
    const allRoles = await this.roleRepository.findAll();
    return allRoles.filter((role) => ids.includes(role.id));
  }

  private async resolveTargetDepartments(
    ids: string[] | undefined,
  ): Promise<Department[]> {
    if (!ids || ids.length === 0) return [];
    const allDepartments = await this.departmentRepository.findAll();
    return allDepartments.filter((dept) => ids.includes(dept.id));
  }
}
