import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CurrentUser } from '../../authentication/presentation/decorators/current-user.decorator';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { InviteEmployeeDto } from '../application/dto/invite-employee.dto';
import { UpdateEmployeeDto } from '../application/dto/update-employee.dto';
import { UpdateMyProfileDto } from '../application/dto/update-my-profile.dto';
import { EmployeesService } from '../application/employees.service';
import { avatarUploadOptions } from './avatar-upload.config';
import { documentUploadOptions } from './document-upload.config';

@Controller('employees')
export class EmployeesController {
  constructor(private readonly employeesService: EmployeesService) {}

  @Post('invite')
  @Permissions('employees.manage')
  invite(@Body() dto: InviteEmployeeDto) {
    return this.employeesService.invite(dto);
  }

  @Get()
  @Permissions('employees.read')
  findAll() {
    return this.employeesService.findAll();
  }

  @Get('me')
  findMe(@CurrentUser() user: JwtPayload) {
    return this.employeesService.findByUserId(user.sub);
  }

  @Patch('me')
  updateMe(@CurrentUser() user: JwtPayload, @Body() dto: UpdateMyProfileDto) {
    return this.employeesService.updateSelf(user.sub, dto);
  }

  @Post('me/photo')
  @UseInterceptors(FileInterceptor('file', avatarUploadOptions))
  uploadMyPhoto(
    @CurrentUser() user: JwtPayload,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) throw new BadRequestException('No file uploaded');
    return this.employeesService.updateMyPhoto(user.sub, file);
  }

  @Get('me/documents')
  listMyDocuments(@CurrentUser() user: JwtPayload) {
    return this.employeesService.listMyDocuments(user.sub);
  }

  @Post('me/documents')
  @UseInterceptors(FileInterceptor('file', documentUploadOptions))
  uploadMyDocument(
    @CurrentUser() user: JwtPayload,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) throw new BadRequestException('No file uploaded');
    return this.employeesService.uploadMyDocument(user.sub, file);
  }

  @Delete('me/documents/:documentId')
  deleteMyDocument(
    @CurrentUser() user: JwtPayload,
    @Param('documentId') documentId: string,
  ) {
    return this.employeesService.deleteMyDocument(user.sub, documentId);
  }

  @Get(':id')
  @Permissions('employees.read')
  findOne(@Param('id') id: string) {
    return this.employeesService.findById(id);
  }

  @Patch(':id')
  @Permissions('employees.manage')
  update(@Param('id') id: string, @Body() dto: UpdateEmployeeDto) {
    return this.employeesService.update(id, dto);
  }

  @Get(':id/documents')
  @Permissions('employees.manage')
  listDocuments(@Param('id') id: string) {
    return this.employeesService.listDocuments(id);
  }

  @Post(':id/documents')
  @Permissions('employees.manage')
  @UseInterceptors(FileInterceptor('file', documentUploadOptions))
  uploadDocument(
    @Param('id') id: string,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) throw new BadRequestException('No file uploaded');
    return this.employeesService.uploadDocument(id, file);
  }

  @Delete(':id/documents/:documentId')
  @Permissions('employees.manage')
  deleteDocument(
    @Param('id') id: string,
    @Param('documentId') documentId: string,
  ) {
    return this.employeesService.deleteDocument(id, documentId);
  }
}
