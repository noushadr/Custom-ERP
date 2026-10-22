import { createReadStream } from 'fs';
import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Put,
  Query,
  StreamableFile,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CurrentUser } from '../../authentication/presentation/decorators/current-user.decorator';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { CreateKnowledgeBaseArticleDto } from '../application/dto/create-knowledge-base-article.dto';
import { CreateKnowledgeBaseFileArticleDto } from '../application/dto/create-knowledge-base-file-article.dto';
import { ReplaceKnowledgeBaseFileDto } from '../application/dto/replace-knowledge-base-file.dto';
import { UpdateKnowledgeBaseArticleDto } from '../application/dto/update-knowledge-base-article.dto';
import {
  type KnowledgeBaseFileDownload,
  KnowledgeBaseService,
} from '../application/knowledge-base.service';
import { knowledgeBaseUploadOptions } from './knowledge-base-upload.config';

/** Streams an uploaded file back as a download. The type comes from the
 * server-side extension map, and `attachment` plus the global `nosniff`
 * header mean the browser never renders an uploaded file inline from our
 * origin. */
function toStreamableFile(download: KnowledgeBaseFileDownload): StreamableFile {
  return new StreamableFile(createReadStream(download.absolutePath), {
    type: download.mimeType,
    disposition: `attachment; filename*=UTF-8''${encodeURIComponent(download.fileName)}`,
  });
}

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

  /** Creates an article whose body is an uploaded file (multipart: `file`
   * plus the same title/visibility fields as a written article). */
  @Post('file-article')
  @Permissions(PERMISSION)
  @UseInterceptors(FileInterceptor('file', knowledgeBaseUploadOptions))
  createFileArticle(
    @Body() dto: CreateKnowledgeBaseFileArticleDto,
    @CurrentUser() user: JwtPayload,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) throw new BadRequestException('No file uploaded');
    return this.knowledgeBaseService.createFileArticle(dto, file, user.sub);
  }

  @Put(':id/file')
  @Permissions(PERMISSION)
  @UseInterceptors(FileInterceptor('file', knowledgeBaseUploadOptions))
  replaceFile(
    @Param('id') id: string,
    @Body() dto: ReplaceKnowledgeBaseFileDto,
    @CurrentUser() user: JwtPayload,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) throw new BadRequestException('No file uploaded');
    return this.knowledgeBaseService.replaceFile(id, file, dto, user.sub);
  }

  @Get(':id/file')
  async downloadFile(
    @Param('id') id: string,
    @CurrentUser() user: JwtPayload,
  ) {
    const actorHasOverride = user.permissions.includes(PERMISSION);
    return toStreamableFile(
      await this.knowledgeBaseService.getFileForActor(
        id,
        user.sub,
        actorHasOverride,
      ),
    );
  }

  @Get(':id/versions/:versionId/file')
  async downloadVersionFile(
    @Param('id') id: string,
    @Param('versionId') versionId: string,
    @CurrentUser() user: JwtPayload,
  ) {
    const actorHasOverride = user.permissions.includes(PERMISSION);
    return toStreamableFile(
      await this.knowledgeBaseService.getVersionFileForActor(
        id,
        versionId,
        user.sub,
        actorHasOverride,
      ),
    );
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
