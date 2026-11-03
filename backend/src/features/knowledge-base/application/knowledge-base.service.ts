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
import { existsSync } from 'fs';
import { unlink } from 'fs/promises';
import { CreateKnowledgeBaseArticleDto } from './dto/create-knowledge-base-article.dto';
import { CreateKnowledgeBaseFileArticleDto } from './dto/create-knowledge-base-file-article.dto';
import { ReplaceKnowledgeBaseFileDto } from './dto/replace-knowledge-base-file.dto';
import { UpdateKnowledgeBaseArticleDto } from './dto/update-knowledge-base-article.dto';
import {
  KNOWLEDGE_BASE_MAX_FILES,
  mimeTypeForExtension,
  storedFilePath,
} from '../presentation/knowledge-base-upload.config';
import type { KnowledgeBaseStoredFile } from '../domain/entities/knowledge-base-stored-file';
import { KnowledgeBaseContentKind } from '../domain/enums/knowledge-base-content-kind.enum';
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

/** What the controller needs to stream an uploaded file back to a reader. */
export interface KnowledgeBaseFileDownload {
  absolutePath: string;
  fileName: string;
  mimeType: string;
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
    return toKnowledgeBaseArticleResponse(
      await this.getArticleForActorEntity(id, actorUserId, actorHasOverride),
    );
  }

  /** The single visibility gate every read of an article — its text, its
   * history, and its uploaded files — goes through. */
  private async getArticleForActorEntity(
    id: string,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<KnowledgeBaseArticle> {
    const article = await this.getArticleOr404(id);
    if (!actorHasOverride) {
      // Archived means gone for everyone but managers — by id as well as in
      // the list, so a saved link or file URL stops working too.
      if (article.isArchived) throw new NotFoundException('Article not found');
      const viewer = await this.resolveViewer(actorUserId);
      if (!this.isVisibleTo(article, viewer)) {
        throw new ForbiddenException(
          'You do not have access to this article',
        );
      }
    }
    return article;
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

  /** The article's current uploaded file. Goes through the same visibility
   * check as reading the article itself — uploaded files are never reachable
   * by URL alone (they live outside the statically served `uploads/`). */
  async getFileForActor(
    articleId: string,
    index: number,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<KnowledgeBaseFileDownload> {
    const article = await this.getArticleForActorEntity(
      articleId,
      actorUserId,
      actorHasOverride,
    );
    return this.toDownload(article.files, index);
  }

  async getVersionFileForActor(
    articleId: string,
    versionId: string,
    index: number,
    actorUserId: string,
    actorHasOverride: boolean,
  ): Promise<KnowledgeBaseFileDownload> {
    await this.getArticleForActorEntity(
      articleId,
      actorUserId,
      actorHasOverride,
    );
    const version = await this.versionRepository.findById(versionId);
    if (!version || version.articleId !== articleId) {
      throw new NotFoundException('Version not found');
    }
    return this.toDownload(version.files, index);
  }

  // ---- Writes ----

  /** Creates an article whose body is 1-3 uploaded files instead of written
   * text. [files] have already been saved to disk by the upload interceptor;
   * if anything below rejects the request they are removed again so a failed
   * create never leaves orphans behind. */
  async createFileArticle(
    dto: CreateKnowledgeBaseFileArticleDto,
    files: Express.Multer.File[],
    actorUserId: string,
  ): Promise<KnowledgeBaseArticleResponseDto> {
    let persisted = false;
    try {
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
      article.content = [];
      article.contentKind = KnowledgeBaseContentKind.FILE;
      this.applyFiles(article, files);
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
      persisted = true;
      await this.versionRepository.save(
        this.buildVersion(saved, actorUserId, actorName),
      );
      return toKnowledgeBaseArticleResponse(
        await this.getArticleOr404(saved.id),
      );
    } catch (error) {
      // Once the article row points at the files they must stay on disk.
      if (!persisted) await this.discardUploads(files);
      throw error;
    }
  }

  /** Swaps a file article's files for a new set, recording a new version. The
   * previous files stay on disk so their version can still be opened. */
  async replaceFiles(
    id: string,
    files: Express.Multer.File[],
    dto: ReplaceKnowledgeBaseFileDto,
    actorUserId: string,
  ): Promise<KnowledgeBaseArticleResponseDto> {
    let persisted = false;
    try {
      const article = await this.getArticleOr404(id);
      if (article.contentKind !== KnowledgeBaseContentKind.FILE) {
        throw new BadRequestException(
          'This is a written article — it has no files to replace',
        );
      }
      const actorName = await resolveActorName(
        this.employeeRepository,
        this.userRepository,
        actorUserId,
      );

      if (dto.title !== undefined) article.title = dto.title;
      this.applyFiles(article, files);
      article.versionNumber += 1;
      article.lastEditedByUserId = actorUserId;
      article.lastEditedByName = actorName;
      const saved = await this.articleRepository.save(article);
      persisted = true;
      await this.versionRepository.save(
        this.buildVersion(saved, actorUserId, actorName),
      );
      return toKnowledgeBaseArticleResponse(
        await this.getArticleOr404(saved.id),
      );
    } catch (error) {
      if (!persisted) await this.discardUploads(files);
      throw error;
    }
  }

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
    article.contentKind = KnowledgeBaseContentKind.RICH_TEXT;
    article.files = [];
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

    await this.versionRepository.save(
      this.buildVersion(saved, actorUserId, actorName),
    );

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
    if (
      article.contentKind === KnowledgeBaseContentKind.FILE &&
      dto.content !== undefined
    ) {
      throw new BadRequestException(
        'This article is an uploaded file and has no written content — ' +
          'upload a replacement file instead',
      );
    }

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
      await this.versionRepository.save(
        this.buildVersion(saved, actorUserId, actorName),
      );
    }

    return toKnowledgeBaseArticleResponse(await this.getArticleOr404(saved.id));
  }

  // ---- Helpers ----

  /** An immutable snapshot of the article as it is right now, including
   * which file it pointed at (null for a written article). */
  private buildVersion(
    article: KnowledgeBaseArticle,
    editorUserId: string,
    editorName: string,
  ): KnowledgeBaseArticleVersion {
    const version = new KnowledgeBaseArticleVersion();
    version.articleId = article.id;
    version.versionNumber = article.versionNumber;
    version.title = article.title;
    version.content = article.content;
    version.files = [...(article.files ?? [])];
    version.editorUserId = editorUserId;
    version.editorName = editorName;
    return version;
  }

  /** Points the article at its uploaded files. The Content-Type we will
   * serve is taken from each file's extension (see
   * knowledge-base-upload.config), not from whatever the uploader's browser
   * claimed. */
  private applyFiles(
    article: KnowledgeBaseArticle,
    files: Express.Multer.File[],
  ): void {
    if (files.length === 0 || files.length > KNOWLEDGE_BASE_MAX_FILES) {
      throw new BadRequestException(
        `Upload between 1 and ${KNOWLEDGE_BASE_MAX_FILES} files`,
      );
    }
    article.files = files.map((file) => {
      const mimeType = mimeTypeForExtension(file.originalname);
      if (!mimeType) {
        throw new BadRequestException('Unsupported file type');
      }
      return {
        fileName: file.originalname,
        storedFileName: file.filename,
        mimeType,
        sizeBytes: file.size,
      };
    });
  }

  /** Removes just-uploaded files that never made it into the database. */
  private async discardUploads(files: Express.Multer.File[]): Promise<void> {
    await Promise.all(
      files.map(async (file) => {
        try {
          await unlink(file.path);
        } catch {
          // Already gone or never written — nothing left to clean up.
        }
      }),
    );
  }

  private toDownload(
    files: KnowledgeBaseStoredFile[] | null | undefined,
    index: number,
  ): KnowledgeBaseFileDownload {
    const file = files?.[index];
    if (!file) {
      throw new NotFoundException('This article has no such uploaded file');
    }
    const absolutePath = storedFilePath(file.storedFileName);
    if (!existsSync(absolutePath)) {
      throw new NotFoundException('The uploaded file is no longer available');
    }
    return {
      absolutePath,
      fileName: file.fileName,
      mimeType: file.mimeType,
    };
  }

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
