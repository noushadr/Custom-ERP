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
import { KnowledgeBaseArticleVersion } from '../domain/entities/knowledge-base-article-version.entity';
import { KnowledgeBaseArticle } from '../domain/entities/knowledge-base-article.entity';
import { KnowledgeBaseVisibility } from '../domain/enums/knowledge-base-visibility.enum';
import type { KnowledgeBaseArticleVersionRepository } from '../domain/repositories/knowledge-base-article-version-repository.interface';
import type { KnowledgeBaseArticleRepository } from '../domain/repositories/knowledge-base-article-repository.interface';
import { KnowledgeBaseService } from './knowledge-base.service';

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
});
