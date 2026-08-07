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
import { AddEducationRecordDto } from '../application/dto/add-education-record.dto';
import { AddSalaryRecordDto } from '../application/dto/add-salary-record.dto';
import { InviteEmployeeDto } from '../application/dto/invite-employee.dto';
import { UpdateEmployeeDto } from '../application/dto/update-employee.dto';
import { UpdateMyProfileDto } from '../application/dto/update-my-profile.dto';
import { UploadDocumentDto } from '../application/dto/upload-document.dto';
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
    @Body() dto: UploadDocumentDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) throw new BadRequestException('No file uploaded');
    return this.employeesService.uploadMyDocument(
      user.sub,
      file,
      dto.documentType,
    );
  }

  @Delete('me/documents/:documentId')
  deleteMyDocument(
    @CurrentUser() user: JwtPayload,
    @Param('documentId') documentId: string,
  ) {
    return this.employeesService.deleteMyDocument(user.sub, documentId);
  }

  @Get('me/audit-log')
  getMyAuditLog(@CurrentUser() user: JwtPayload) {
    return this.employeesService.getMyAuditLog(user.sub);
  }

  @Get('me/salary-history')
  getMySalaryHistory(@CurrentUser() user: JwtPayload) {
    return this.employeesService.getMySalaryHistory(user.sub);
  }

  @Get('me/education-history')
  getMyEducationHistory(@CurrentUser() user: JwtPayload) {
    return this.employeesService.getMyEducationHistory(user.sub);
  }

  @Post('me/education-history')
  addMyEducationRecord(
    @CurrentUser() user: JwtPayload,
    @Body() dto: AddEducationRecordDto,
  ) {
    return this.employeesService.addMyEducationRecord(user.sub, dto);
  }

  @Delete('me/education-history/:recordId')
  deleteMyEducationRecord(
    @CurrentUser() user: JwtPayload,
    @Param('recordId') recordId: string,
  ) {
    return this.employeesService.deleteMyEducationRecord(user.sub, recordId);
  }

  // Must come before @Get(':id') — otherwise "audit-log" would be captured
  // as the :id parameter instead of matching this route.
  @Get('audit-log')
  @Permissions('audit.viewAll')
  getCompanyAuditLog() {
    return this.employeesService.getCompanyAuditLog();
  }

  @Get(':id')
  @Permissions('employees.read')
  findOne(@Param('id') id: string) {
    return this.employeesService.findById(id);
  }

  @Patch(':id')
  @Permissions('employees.manage')
  update(
    @Param('id') id: string,
    @Body() dto: UpdateEmployeeDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.employeesService.update(id, dto, user.sub);
  }

  @Get(':id/audit-log')
  @Permissions('employees.manage')
  getAuditLog(@Param('id') id: string) {
    return this.employeesService.getAuditLog(id);
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
    @Body() dto: UploadDocumentDto,
    @CurrentUser() user: JwtPayload,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) throw new BadRequestException('No file uploaded');
    return this.employeesService.uploadDocument(
      id,
      file,
      user.sub,
      dto.documentType,
    );
  }

  @Delete(':id/documents/:documentId')
  @Permissions('employees.manage')
  deleteDocument(
    @Param('id') id: string,
    @Param('documentId') documentId: string,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.employeesService.deleteDocument(id, documentId, user.sub);
  }

  @Get(':id/salary-history')
  @Permissions('employees.manage')
  getSalaryHistory(@Param('id') id: string) {
    return this.employeesService.getSalaryHistory(id);
  }

  @Post(':id/salary-history')
  @Permissions('employees.manage')
  addSalaryRecord(
    @Param('id') id: string,
    @Body() dto: AddSalaryRecordDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.employeesService.addSalaryRecord(id, dto, user.sub);
  }

  @Delete(':id/salary-history/:recordId')
  @Permissions('employees.manage')
  deleteSalaryRecord(
    @Param('id') id: string,
    @Param('recordId') recordId: string,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.employeesService.deleteSalaryRecord(id, recordId, user.sub);
  }

  @Get(':id/education-history')
  @Permissions('employees.manage')
  getEducationHistory(@Param('id') id: string) {
    return this.employeesService.getEducationHistory(id);
  }

  @Post(':id/education-history')
  @Permissions('employees.manage')
  addEducationRecord(
    @Param('id') id: string,
    @Body() dto: AddEducationRecordDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.employeesService.addEducationRecord(id, dto, user.sub);
  }

  @Delete(':id/education-history/:recordId')
  @Permissions('employees.manage')
  deleteEducationRecord(
    @Param('id') id: string,
    @Param('recordId') recordId: string,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.employeesService.deleteEducationRecord(id, recordId, user.sub);
  }
}
