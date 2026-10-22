import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Role } from '../../authentication/domain/entities/role.entity';
import type { RoleRepository } from '../../authentication/domain/repositories/role-repository.interface';
import type { UserRepository } from '../../authentication/domain/repositories/user-repository.interface';
import { Department } from '../../departments/domain/entities/department.entity';
import type { DepartmentRepository } from '../../departments/domain/repositories/department-repository.interface';
import { Employee } from '../../employee/domain/entities/employee.entity';
import type { EmployeeRepository } from '../../employee/domain/repositories/employee-repository.interface';
import { existsSync } from 'fs';
import { unlink } from 'fs/promises';
import { KnowledgeBaseArticleVersion } from '../domain/entities/knowledge-base-article-version.entity';
import { KnowledgeBaseArticle } from '../domain/entities/knowledge-base-article.entity';
import { KnowledgeBaseContentKind } from '../domain/enums/knowledge-base-content-kind.enum';
import { KnowledgeBaseVisibility } from '../domain/enums/knowledge-base-visibility.enum';
import type { KnowledgeBaseArticleVersionRepository } from '../domain/repositories/knowledge-base-article-version-repository.interface';
import type { KnowledgeBaseArticleRepository } from '../domain/repositories/knowledge-base-article-repository.interface';
import { KnowledgeBaseService } from './knowledge-base.service';

// `fs` namespaces are read-only under TS interop, so jest.spyOn can't patch
// them — mock the two functions the service touches instead.
jest.mock('fs', () => ({
  ...jest.requireActual<typeof import('fs')>('fs'),
  existsSync: jest.fn(),
}));
jest.mock('fs/promises', () => ({
  ...jest.requireActual<typeof import('fs/promises')>('fs/promises'),
  unlink: jest.fn(),
}));

function buildRole(overrides: Partial<Role> = {}): Role {
  return { id: 'role-1', name: 'Team Lead', ...overrides } as Role;
}

function buildDepartment(overrides: Partial<Department> = {}): Department {
  return { id: 'dept-1', name: 'Engineering', ...overrides } as Department;
}

function buildEmployee(overrides: Partial<Employee> = {}): Employee {
  return {
    id: 'employee-1',
    userId: 'user-1',
    firstName: 'Jane',
    lastName: 'Doe',
    departmentId: 'dept-1',
    user: { role: buildRole() },
    ...overrides,
  } as Employee;
}

function buildArticle(overrides: Partial<KnowledgeBaseArticle> = {}): KnowledgeBaseArticle {
  return {
    id: 'article-1',
    title: 'Onboarding SOP',
    content: { ops: [{ insert: 'hello' }] },
    visibilityType: KnowledgeBaseVisibility.EVERYONE,
    targetRoles: [],
    targetDepartments: [],
    authorUserId: 'author-1',
    authorName: 'Author Person',
    lastEditedByUserId: 'author-1',
    lastEditedByName: 'Author Person',
    versionNumber: 1,
    isArchived: false,
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    updatedAt: new Date('2026-01-01T00:00:00.000Z'),
    ...overrides,
  } as KnowledgeBaseArticle;
}

function buildVersion(
  overrides: Partial<KnowledgeBaseArticleVersion> = {},
): KnowledgeBaseArticleVersion {
  return {
    id: 'version-1',
    articleId: 'article-1',
    versionNumber: 1,
    title: 'Onboarding SOP',
    content: { ops: [{ insert: 'hello' }] },
    editorUserId: 'author-1',
    editorName: 'Author Person',
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    ...overrides,
  } as KnowledgeBaseArticleVersion;
}

describe('KnowledgeBaseService', () => {
  let service: KnowledgeBaseService;
  let articleRepository: jest.Mocked<KnowledgeBaseArticleRepository>;
  let versionRepository: jest.Mocked<KnowledgeBaseArticleVersionRepository>;
  let employeeRepository: jest.Mocked<EmployeeRepository>;
  let userRepository: jest.Mocked<UserRepository>;
  let roleRepository: jest.Mocked<RoleRepository>;
  let departmentRepository: jest.Mocked<DepartmentRepository>;

  beforeEach(() => {
    articleRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      save: jest.fn((item) => Promise.resolve(item)),
    };
    versionRepository = {
      findByArticleId: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      save: jest.fn((item) => Promise.resolve(item)),
    };
    employeeRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      findByUserId: jest.fn(),
      findByReportingManagerId: jest.fn(),
      count: jest.fn(),
      save: jest.fn(),
    };
    userRepository = {
      findByEmail: jest.fn(),
      findById: jest.fn(),
      findAll: jest.fn(),
      save: jest.fn(),
    };
    roleRepository = {
      findByName: jest.fn(),
      findById: jest.fn(),
      findAll: jest.fn().mockResolvedValue([buildRole()]),
      save: jest.fn(),
      remove: jest.fn(),
    };
    departmentRepository = {
      findAll: jest.fn().mockResolvedValue([buildDepartment()]),
      findById: jest.fn(),
      save: jest.fn(),
      remove: jest.fn(),
    };

    service = new KnowledgeBaseService(
      articleRepository,
      versionRepository,
      employeeRepository,
      userRepository,
      roleRepository,
      departmentRepository,
    );
  });

  describe('getVisibleArticles', () => {
    it('shows everyone-visibility articles to any viewer', async () => {
      articleRepository.findAll.mockResolvedValue([
        buildArticle({ visibilityType: KnowledgeBaseVisibility.EVERYONE }),
      ]);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ user: { role: buildRole({ name: 'Employee' }) } } as never),
      );

      const result = await service.getVisibleArticles('user-1', false, false);

      expect(result).toHaveLength(1);
    });

    it('hides a roles-targeted article from a viewer with a different role', async () => {
      articleRepository.findAll.mockResolvedValue([
        buildArticle({
          visibilityType: KnowledgeBaseVisibility.ROLES,
          targetRoles: [buildRole({ id: 'role-team-lead', name: 'Team Lead' })],
        }),
      ]);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ user: { role: buildRole({ name: 'Employee' }) } } as never),
      );

      const result = await service.getVisibleArticles('user-1', false, false);

      expect(result).toHaveLength(0);
    });

    it('shows a roles-targeted article to a viewer whose role matches', async () => {
      articleRepository.findAll.mockResolvedValue([
        buildArticle({
          visibilityType: KnowledgeBaseVisibility.ROLES,
          targetRoles: [buildRole({ id: 'role-team-lead', name: 'Team Lead' })],
        }),
      ]);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ user: { role: buildRole({ name: 'Team Lead' }) } } as never),
      );

      const result = await service.getVisibleArticles('user-1', false, false);

      expect(result).toHaveLength(1);
    });

    it('shows a departments-targeted article to a viewer in that department', async () => {
      articleRepository.findAll.mockResolvedValue([
        buildArticle({
          visibilityType: KnowledgeBaseVisibility.DEPARTMENTS,
          targetDepartments: [buildDepartment({ id: 'dept-finance', name: 'Finance' })],
        }),
      ]);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ departmentId: 'dept-finance' }),
      );

      const result = await service.getVisibleArticles('user-1', false, false);

      expect(result).toHaveLength(1);
    });

    it('uses union (OR) semantics for roles+departments — matching either is enough', async () => {
      articleRepository.findAll.mockResolvedValue([
        buildArticle({
          visibilityType: KnowledgeBaseVisibility.ROLES_AND_DEPARTMENTS,
          targetRoles: [buildRole({ id: 'role-hr', name: 'HR/Manager' })],
          targetDepartments: [buildDepartment({ id: 'dept-finance', name: 'Finance' })],
        }),
      ]);
      // Matches the department but not the role — union semantics still show it.
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({
          departmentId: 'dept-finance',
          user: { role: buildRole({ name: 'Employee' }) } as never,
        }),
      );

      const result = await service.getVisibleArticles('user-1', false, false);

      expect(result).toHaveLength(1);
    });

    it('lets a knowledge_base.manage holder see everything, bypassing visibility', async () => {
      articleRepository.findAll.mockResolvedValue([
        buildArticle({
          visibilityType: KnowledgeBaseVisibility.ROLES,
          targetRoles: [buildRole({ id: 'role-team-lead', name: 'Team Lead' })],
        }),
      ]);

      const result = await service.getVisibleArticles('admin-1', true, false);

      expect(result).toHaveLength(1);
      expect(employeeRepository.findByUserId).not.toHaveBeenCalled();
    });

    it('degrades to everyone-only visibility for an actor with no employee profile', async () => {
      articleRepository.findAll.mockResolvedValue([
        buildArticle({ visibilityType: KnowledgeBaseVisibility.EVERYONE }),
        buildArticle({
          id: 'article-2',
          visibilityType: KnowledgeBaseVisibility.ROLES,
          targetRoles: [buildRole({ id: 'role-team-lead', name: 'Team Lead' })],
        }),
      ]);
      employeeRepository.findByUserId.mockResolvedValue(null);

      const result = await service.getVisibleArticles('user-1', false, false);

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('article-1');
    });
  });

  describe('getArticleForActor', () => {
    it('throws NotFoundException when missing', async () => {
      articleRepository.findById.mockResolvedValue(null);

      await expect(
        service.getArticleForActor('missing', 'user-1', false),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('is forbidden for a viewer the article is not targeted at', async () => {
      articleRepository.findById.mockResolvedValue(
        buildArticle({
          visibilityType: KnowledgeBaseVisibility.ROLES,
          targetRoles: [buildRole({ id: 'role-team-lead', name: 'Team Lead' })],
        }),
      );
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ user: { role: buildRole({ name: 'Employee' }) } } as never),
      );

      await expect(
        service.getArticleForActor('article-1', 'user-1', false),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });
  });

  describe('createArticle', () => {
    it('creates the article and its first version', async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ firstName: 'Author', lastName: 'Person' }),
      );
      articleRepository.findById.mockImplementation((id) =>
        Promise.resolve(buildArticle({ id })),
      );

      const result = await service.createArticle(
        {
          title: 'Onboarding SOP',
          content: { ops: [{ insert: 'hello' }] },
          visibilityType: KnowledgeBaseVisibility.EVERYONE,
        },
        'author-user-1',
      );

      expect(result.versionNumber).toBe(1);
      expect(articleRepository.save).toHaveBeenCalledTimes(1);
      expect(versionRepository.save).toHaveBeenCalledTimes(1);
      const savedVersion = versionRepository.save.mock.calls[0][0];
      expect(savedVersion.versionNumber).toBe(1);
    });

    it('rejects a roles visibility type with no roles selected', async () => {
      await expect(
        service.createArticle(
          {
            title: 'Onboarding SOP',
            content: {},
            visibilityType: KnowledgeBaseVisibility.ROLES,
          },
          'author-user-1',
        ),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('updateArticle', () => {
    it('bumps the version and snapshots when content changes', async () => {
      const article = buildArticle();
      articleRepository.findById.mockResolvedValue(article);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ firstName: 'Editor', lastName: 'Person' }),
      );

      await service.updateArticle(
        'article-1',
        { content: { ops: [{ insert: 'updated' }] } },
        'editor-user-1',
      );

      expect(article.versionNumber).toBe(2);
      expect(versionRepository.save).toHaveBeenCalledTimes(1);
      const savedVersion = versionRepository.save.mock.calls[0][0];
      expect(savedVersion.versionNumber).toBe(2);
      expect(savedVersion.editorName).toBe('Editor Person');
    });

    it('does not create a version for a visibility-only update', async () => {
      const article = buildArticle();
      articleRepository.findById.mockResolvedValue(article);

      await service.updateArticle(
        'article-1',
        { isArchived: true },
        'editor-user-1',
      );

      expect(article.versionNumber).toBe(1);
      expect(article.isArchived).toBe(true);
      expect(versionRepository.save).not.toHaveBeenCalled();
      expect(employeeRepository.findByUserId).not.toHaveBeenCalled();
    });
  });

  describe('getVersionForActor', () => {
    it('throws NotFoundException for a version belonging to a different article', async () => {
      articleRepository.findById.mockResolvedValue(buildArticle());
      versionRepository.findById.mockResolvedValue(
        buildVersion({ articleId: 'some-other-article' }),
      );

      await expect(
        service.getVersionForActor('article-1', 'version-1', 'user-1', true),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('returns the version content when it belongs to the article', async () => {
      articleRepository.findById.mockResolvedValue(buildArticle());
      versionRepository.findById.mockResolvedValue(buildVersion());

      const result = await service.getVersionForActor(
        'article-1',
        'version-1',
        'user-1',
        true,
      );

      expect(result.content).toEqual({ ops: [{ insert: 'hello' }] });
    });
  });

  describe('file articles', () => {
    function buildUpload(
      overrides: Partial<Express.Multer.File> = {},
    ): Express.Multer.File {
      return {
        originalname: 'Leave Policy.pdf',
        filename: 'stored-uuid.pdf',
        path: '/storage/knowledge-base/stored-uuid.pdf',
        mimetype: 'application/pdf',
        size: 2048,
        ...overrides,
      } as Express.Multer.File;
    }

    function buildFileArticle(
      overrides: Partial<KnowledgeBaseArticle> = {},
    ): KnowledgeBaseArticle {
      return buildArticle({
        contentKind: KnowledgeBaseContentKind.FILE,
        content: [],
        fileName: 'Leave Policy.pdf',
        storedFileName: 'stored-uuid.pdf',
        fileMimeType: 'application/pdf',
        fileSizeBytes: 2048,
        ...overrides,
      });
    }

    let unlinkSpy: jest.Mock;

    beforeEach(() => {
      unlinkSpy = unlink as unknown as jest.Mock;
      unlinkSpy.mockReset().mockResolvedValue(undefined);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ firstName: 'Author', lastName: 'Person' }),
      );
    });

    it('creates a file article with the file details and a first version pointing at it', async () => {
      articleRepository.findById.mockImplementation((id) =>
        Promise.resolve(buildFileArticle({ id })),
      );

      await service.createFileArticle(
        { title: 'Leave Policy', visibilityType: KnowledgeBaseVisibility.EVERYONE },
        buildUpload(),
        'author-user-1',
      );

      const saved = articleRepository.save.mock.calls[0][0];
      expect(saved.contentKind).toBe(KnowledgeBaseContentKind.FILE);
      expect(saved.content).toEqual([]);
      expect(saved.fileName).toBe('Leave Policy.pdf');
      expect(saved.storedFileName).toBe('stored-uuid.pdf');
      expect(saved.fileSizeBytes).toBe(2048);
      const version = versionRepository.save.mock.calls[0][0];
      expect(version.versionNumber).toBe(1);
      expect(version.storedFileName).toBe('stored-uuid.pdf');
      expect(unlinkSpy).not.toHaveBeenCalled();
    });

    it('serves the type implied by the extension, not the one the browser claimed', async () => {
      articleRepository.findById.mockImplementation((id) =>
        Promise.resolve(buildFileArticle({ id })),
      );

      await service.createFileArticle(
        { title: 'Sneaky', visibilityType: KnowledgeBaseVisibility.EVERYONE },
        buildUpload({ mimetype: 'text/html' }),
        'author-user-1',
      );

      expect(articleRepository.save.mock.calls[0][0].fileMimeType).toBe(
        'application/pdf',
      );
    });

    it('rejects an unsupported extension and removes the uploaded file', async () => {
      const upload = buildUpload({
        originalname: 'page.html',
        path: '/storage/knowledge-base/x.html',
      });

      await expect(
        service.createFileArticle(
          { title: 'Bad', visibilityType: KnowledgeBaseVisibility.EVERYONE },
          upload,
          'author-user-1',
        ),
      ).rejects.toBeInstanceOf(BadRequestException);

      expect(articleRepository.save).not.toHaveBeenCalled();
      expect(unlinkSpy).toHaveBeenCalledWith(upload.path);
    });

    it('removes the uploaded file when the targeting is invalid', async () => {
      const upload = buildUpload();

      await expect(
        service.createFileArticle(
          { title: 'Roles only', visibilityType: KnowledgeBaseVisibility.ROLES },
          upload,
          'author-user-1',
        ),
      ).rejects.toBeInstanceOf(BadRequestException);

      expect(unlinkSpy).toHaveBeenCalledWith(upload.path);
    });

    it('refuses written content on an uploaded-file article', async () => {
      articleRepository.findById.mockResolvedValue(buildFileArticle());

      await expect(
        service.updateArticle(
          'article-1',
          { content: { ops: [{ insert: 'x' }] } },
          'editor-user-1',
        ),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(articleRepository.save).not.toHaveBeenCalled();
    });

    it('keeps pointing a retitled file article at the same file in the new version', async () => {
      articleRepository.findById.mockResolvedValue(buildFileArticle());

      await service.updateArticle(
        'article-1',
        { title: 'Leave Policy 2026' },
        'editor-user-1',
      );

      const version = versionRepository.save.mock.calls[0][0];
      expect(version.versionNumber).toBe(2);
      expect(version.title).toBe('Leave Policy 2026');
      expect(version.storedFileName).toBe('stored-uuid.pdf');
    });

    it('replaces the file, bumps the version and keeps the old file on disk', async () => {
      articleRepository.findById.mockResolvedValue(buildFileArticle());

      await service.replaceFile(
        'article-1',
        buildUpload({
          originalname: 'Leave Policy v2.docx',
          filename: 'new-uuid.docx',
          size: 4096,
        }),
        {},
        'editor-user-1',
      );

      const saved = articleRepository.save.mock.calls[0][0];
      expect(saved.versionNumber).toBe(2);
      expect(saved.fileName).toBe('Leave Policy v2.docx');
      expect(saved.storedFileName).toBe('new-uuid.docx');
      expect(saved.fileMimeType).toBe(
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
      expect(versionRepository.save.mock.calls[0][0].storedFileName).toBe(
        'new-uuid.docx',
      );
      // The previous file belongs to version 1 and must still exist.
      expect(unlinkSpy).not.toHaveBeenCalled();
    });

    it('will not replace the file of a written article, and discards the upload', async () => {
      articleRepository.findById.mockResolvedValue(buildArticle());
      const upload = buildUpload();

      await expect(
        service.replaceFile('article-1', upload, {}, 'editor-user-1'),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(unlinkSpy).toHaveBeenCalledWith(upload.path);
    });

    describe('downloads', () => {
      beforeEach(() => {
        (existsSync as jest.Mock).mockReturnValue(true);
      });

      it('returns the file for a viewer the article is visible to', async () => {
        articleRepository.findById.mockResolvedValue(buildFileArticle());
        employeeRepository.findByUserId.mockResolvedValue(buildEmployee());

        const download = await service.getFileForActor('article-1', 'user-1', false);

        expect(download.fileName).toBe('Leave Policy.pdf');
        expect(download.mimeType).toBe('application/pdf');
        expect(download.absolutePath).toContain('stored-uuid.pdf');
      });

      it('is forbidden for a viewer outside the targeted roles — knowing the id is not enough', async () => {
        articleRepository.findById.mockResolvedValue(
          buildFileArticle({
            visibilityType: KnowledgeBaseVisibility.ROLES,
            targetRoles: [buildRole({ id: 'r-hr', name: 'HR/Manager' })],
          }),
        );
        employeeRepository.findByUserId.mockResolvedValue(
          buildEmployee({ user: { role: buildRole({ name: 'Employee' }) } } as never),
        );

        await expect(
          service.getFileForActor('article-1', 'user-1', false),
        ).rejects.toBeInstanceOf(ForbiddenException);
      });

      it('404s for a written article, which has no file', async () => {
        articleRepository.findById.mockResolvedValue(buildArticle());

        await expect(
          service.getFileForActor('article-1', 'user-1', true),
        ).rejects.toBeInstanceOf(NotFoundException);
      });

      it('serves an old version its own file, not the current one', async () => {
        articleRepository.findById.mockResolvedValue(buildFileArticle());
        versionRepository.findById.mockResolvedValue(
          buildVersion({
            id: 'version-1',
            fileName: 'Old.pdf',
            storedFileName: 'old-uuid.pdf',
            fileMimeType: 'application/pdf',
          }),
        );

        const download = await service.getVersionFileForActor(
          'article-1',
          'version-1',
          'user-1',
          true,
        );

        expect(download.fileName).toBe('Old.pdf');
        expect(download.absolutePath).toContain('old-uuid.pdf');
      });

      it('404s when the file has gone missing from disk', async () => {
        (existsSync as jest.Mock).mockReturnValue(false);
        articleRepository.findById.mockResolvedValue(buildFileArticle());

        await expect(
          service.getFileForActor('article-1', 'user-1', true),
        ).rejects.toBeInstanceOf(NotFoundException);
      });
    });
  });
});
