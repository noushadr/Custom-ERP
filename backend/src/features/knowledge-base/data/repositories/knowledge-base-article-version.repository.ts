import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { KnowledgeBaseArticleVersion } from '../../domain/entities/knowledge-base-article-version.entity';
import { KnowledgeBaseArticleVersionRepository } from '../../domain/repositories/knowledge-base-article-version-repository.interface';

@Injectable()
export class TypeOrmKnowledgeBaseArticleVersionRepository
  implements KnowledgeBaseArticleVersionRepository
{
  constructor(
    @InjectRepository(KnowledgeBaseArticleVersion)
    private readonly repository: Repository<KnowledgeBaseArticleVersion>,
  ) {}

  findByArticleId(articleId: string): Promise<KnowledgeBaseArticleVersion[]> {
    return this.repository.find({
      where: { articleId },
      order: { versionNumber: 'DESC' },
    });
  }

  findById(id: string): Promise<KnowledgeBaseArticleVersion | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(
    version: KnowledgeBaseArticleVersion,
  ): Promise<KnowledgeBaseArticleVersion> {
    return this.repository.save(version);
  }
}
