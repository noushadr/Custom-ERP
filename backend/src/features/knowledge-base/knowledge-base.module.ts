import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthenticationModule } from '../authentication/authentication.module';
import { DepartmentsModule } from '../departments/departments.module';
import { EmployeeModule } from '../employee/employee.module';
import { KnowledgeBaseService } from './application/knowledge-base.service';
import { TypeOrmKnowledgeBaseArticleVersionRepository } from './data/repositories/knowledge-base-article-version.repository';
import { TypeOrmKnowledgeBaseArticleRepository } from './data/repositories/knowledge-base-article.repository';
import { KnowledgeBaseArticleVersion } from './domain/entities/knowledge-base-article-version.entity';
import { KnowledgeBaseArticle } from './domain/entities/knowledge-base-article.entity';
import { KNOWLEDGE_BASE_ARTICLE_VERSION_REPOSITORY } from './domain/repositories/knowledge-base-article-version-repository.interface';
import { KNOWLEDGE_BASE_ARTICLE_REPOSITORY } from './domain/repositories/knowledge-base-article-repository.interface';
import { KnowledgeBaseController } from './presentation/knowledge-base.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([KnowledgeBaseArticle, KnowledgeBaseArticleVersion]),
    AuthenticationModule,
    EmployeeModule,
    DepartmentsModule,
  ],
  controllers: [KnowledgeBaseController],
  providers: [
    KnowledgeBaseService,
    {
      provide: KNOWLEDGE_BASE_ARTICLE_REPOSITORY,
      useClass: TypeOrmKnowledgeBaseArticleRepository,
    },
    {
      provide: KNOWLEDGE_BASE_ARTICLE_VERSION_REPOSITORY,
      useClass: TypeOrmKnowledgeBaseArticleVersionRepository,
    },
  ],
  exports: [KnowledgeBaseService],
})
export class KnowledgeBaseModule {}
