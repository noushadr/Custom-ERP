import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { KnowledgeBaseArticle } from '../../domain/entities/knowledge-base-article.entity';
import { KnowledgeBaseArticleRepository } from '../../domain/repositories/knowledge-base-article-repository.interface';

@Injectable()
export class TypeOrmKnowledgeBaseArticleRepository
  implements KnowledgeBaseArticleRepository
{
  constructor(
    @InjectRepository(KnowledgeBaseArticle)
    private readonly repository: Repository<KnowledgeBaseArticle>,
  ) {}

  findAll(includeArchived = false): Promise<KnowledgeBaseArticle[]> {
    return this.repository.find({
      where: includeArchived ? {} : { isArchived: false },
      order: { createdAt: 'DESC' },
    });
  }

  findById(id: string): Promise<KnowledgeBaseArticle | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(article: KnowledgeBaseArticle): Promise<KnowledgeBaseArticle> {
    return this.repository.save(article);
  }
}
