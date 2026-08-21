import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { CurrentUser } from '../../authentication/presentation/decorators/current-user.decorator';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { CompletePerformanceReviewDto } from '../application/dto/complete-performance-review.dto';
import { CreatePerformanceReviewCriterionDto } from '../application/dto/create-performance-review-criterion.dto';
import { CreatePerformanceReviewDto } from '../application/dto/create-performance-review.dto';
import { ReorderPerformanceReviewCriteriaDto } from '../application/dto/reorder-performance-review-criteria.dto';
import { SetSelfAssessmentDto } from '../application/dto/set-self-assessment.dto';
import { UpdatePerformanceReviewCriterionDto } from '../application/dto/update-performance-review-criterion.dto';
import { UpdatePerformanceReviewDto } from '../application/dto/update-performance-review.dto';
import { PerformanceReviewsService } from '../application/performance-reviews.service';

const PERMISSION = 'performance.manage';

@Controller('performance-reviews')
export class PerformanceReviewsController {
  constructor(
    private readonly performanceReviewsService: PerformanceReviewsService,
  ) {}

  @Get('criteria')
  getCriteria(@Query('includeArchived') includeArchived?: string) {
    return this.performanceReviewsService.getCriteria(
      includeArchived === 'true',
    );
  }

  // Must come before @Patch('criteria/:id') — otherwise "reorder" would be
  // captured as the :id parameter instead of matching this route.
  @Patch('criteria/reorder')
  @Permissions(PERMISSION)
  reorderCriteria(@Body() dto: ReorderPerformanceReviewCriteriaDto) {
    return this.performanceReviewsService.reorderCriteria(dto);
  }

  @Post('criteria')
  @Permissions(PERMISSION)
  createCriterion(@Body() dto: CreatePerformanceReviewCriterionDto) {
    return this.performanceReviewsService.createCriterion(dto);
  }

  @Patch('criteria/:id')
  @Permissions(PERMISSION)
  updateCriterion(
    @Param('id') id: string,
    @Body() dto: UpdatePerformanceReviewCriterionDto,
  ) {
    return this.performanceReviewsService.updateCriterion(id, dto);
  }

  @Delete('criteria/:id')
  @Permissions(PERMISSION)
  @HttpCode(204)
  deleteCriterion(@Param('id') id: string) {
    return this.performanceReviewsService.deleteCriterion(id);
  }

  @Get('me')
  getMyReviews(@CurrentUser() user: JwtPayload) {
    return this.performanceReviewsService.getMyReviews(user.sub);
  }

  @Get('pending-manager-action')
  getPendingManagerAction(@CurrentUser() user: JwtPayload) {
    return this.performanceReviewsService.getPendingManagerAction(user.sub);
  }

  @Get('pending-hr-finalization')
  @Permissions(PERMISSION)
  getPendingHrFinalization() {
    return this.performanceReviewsService.getPendingHrFinalization();
  }

  @Get('pending')
  @Permissions(PERMISSION)
  getAllPendingReviews() {
    return this.performanceReviewsService.getAllPendingReviews();
  }

  @Get('finalized')
  @Permissions(PERMISSION)
  getFinalizedReviews() {
    return this.performanceReviewsService.getFinalizedReviews();
  }

  @Get('employee/:employeeId')
  @Permissions(PERMISSION)
  getEmployeeReviews(@Param('employeeId') employeeId: string) {
    return this.performanceReviewsService.getEmployeeReviews(employeeId);
  }

  @Get('due-check/preview')
  @Permissions(PERMISSION)
  previewDueCheck() {
    return this.performanceReviewsService.previewDueCheck();
  }

  @Get('latest-by-employee')
  @Permissions(PERMISSION)
  getLatestReviewSummaries() {
    return this.performanceReviewsService.getLatestReviewSummaries();
  }

  // Must come after every other static-segment GET route above — otherwise
  // this would capture e.g. "me" or "criteria" as :id.
  @Get(':id')
  getReview(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    const actorHasOverride = user.permissions.includes(PERMISSION);
    return this.performanceReviewsService.getReviewByIdForActor(
      id,
      user.sub,
      actorHasOverride,
    );
  }

  @Post('due-check/run')
  @Permissions(PERMISSION)
  runDueCheck() {
    return this.performanceReviewsService.runDueCheck();
  }

  @Post()
  @Permissions(PERMISSION)
  createManualReview(@Body() dto: CreatePerformanceReviewDto) {
    return this.performanceReviewsService.createManualReview(dto);
  }

  @Patch(':id/complete')
  completeReview(
    @Param('id') id: string,
    @Body() dto: CompletePerformanceReviewDto,
    @CurrentUser() user: JwtPayload,
  ) {
    const actorHasOverride = user.permissions.includes(PERMISSION);
    return this.performanceReviewsService.completeReview(
      id,
      dto,
      user.sub,
      actorHasOverride,
    );
  }

  @Patch(':id/self-assessment')
  setSelfAssessment(
    @Param('id') id: string,
    @Body() dto: SetSelfAssessmentDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.performanceReviewsService.setSelfAssessment(
      id,
      dto.comments,
      user.sub,
    );
  }

  @Patch(':id/finalize')
  @Permissions(PERMISSION)
  finalizeReview(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.performanceReviewsService.finalizeReview(id, user.sub);
  }

  @Patch(':id')
  @Permissions(PERMISSION)
  adminUpdateReview(
    @Param('id') id: string,
    @Body() dto: UpdatePerformanceReviewDto,
  ) {
    return this.performanceReviewsService.adminUpdateReview(id, dto);
  }
}
