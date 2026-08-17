import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
} from '@nestjs/common';
import { CurrentUser } from '../../authentication/presentation/decorators/current-user.decorator';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { CreateNoticeDto } from '../application/dto/create-notice.dto';
import { UpdateNoticeDto } from '../application/dto/update-notice.dto';
import { NoticesService } from '../application/notices.service';

@Controller('notices')
export class NoticesController {
  constructor(private readonly noticesService: NoticesService) {}

  @Get()
  findAll() {
    return this.noticesService.findAll();
  }

  @Post()
  @Permissions('notices.manage')
  create(@Body() dto: CreateNoticeDto, @CurrentUser() user: JwtPayload) {
    return this.noticesService.create(dto, user.sub);
  }

  @Patch(':id')
  @Permissions('notices.manage')
  update(@Param('id') id: string, @Body() dto: UpdateNoticeDto) {
    return this.noticesService.update(id, dto);
  }

  @Delete(':id')
  @Permissions('notices.manage')
  delete(@Param('id') id: string) {
    return this.noticesService.delete(id);
  }
}
