import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { CurrentUser } from '../../authentication/presentation/decorators/current-user.decorator';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { CreateKnowledgeBaseArticleDto } from '../application/dto/create-knowledge-base-article.dto';
import { UpdateKnowledgeBaseArticleDto } from '../application/dto/update-knowledge-base-article.dto';
import { KnowledgeBaseService } from '../application/knowledge-base.service';

const PERMISSION = 'knowledge_base.manage';

@Controller('knowledge-base')
export class KnowledgeBaseController {
  constructor(private readonly knowledgeBaseService: KnowledgeBaseService) {}

  @Get()
  getVisibleArticles(
    @CurrentUser() user: JwtPayload,
    @Query('includeArchived') includeArchived?: string,
  ) {
    const actorHasOverride = user.permissions.includes(PERMISSION);
    return this.knowledgeBaseService.getVisibleArticles(
      user.sub,
      actorHasOverride,
      includeArchived === 'true',
    );
  }

  @Post()
  @Permissions(PERMISSION)
  createArticle(
    @Body() dto: CreateKnowledgeBaseArticleDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.knowledgeBaseService.createArticle(dto, user.sub);
  }

  // Must come before @Get(':id') — otherwise "versions" would be captured
  // as the :id parameter instead of matching this route.
  @Get(':id/versions')
  getVersionHistory(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    const actorHasOverride = user.permissions.includes(PERMISSION);
    return this.knowledgeBaseService.getVersionHistory(
      id,
      user.sub,
      actorHasOverride,
    );
  }

  @Get(':id/versions/:versionId')
  getVersion(
    @Param('id') id: string,
    @Param('versionId') versionId: string,
    @CurrentUser() user: JwtPayload,
  ) {
    const actorHasOverride = user.permissions.includes(PERMISSION);
    return this.knowledgeBaseService.getVersionForActor(
      id,
      versionId,
      user.sub,
      actorHasOverride,
    );
  }

  @Get(':id')
  getArticle(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    const actorHasOverride = user.permissions.includes(PERMISSION);
    return this.knowledgeBaseService.getArticleForActor(
      id,
      user.sub,
      actorHasOverride,
    );
  }

  @Patch(':id')
  @Permissions(PERMISSION)
  updateArticle(
    @Param('id') id: string,
    @Body() dto: UpdateKnowledgeBaseArticleDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.knowledgeBaseService.updateArticle(id, dto, user.sub);
  }
}
