import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthenticationModule } from '../authentication/authentication.module';
import { EmployeeModule } from '../employee/employee.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PerformanceReviewsService } from './application/performance-reviews.service';
import { TypeOrmPerformanceReviewCriterionRepository } from './data/repositories/performance-review-criterion.repository';
import { TypeOrmPerformanceReviewResponseRepository } from './data/repositories/performance-review-response.repository';
import { TypeOrmPerformanceReviewRepository } from './data/repositories/performance-review.repository';
import { PerformanceReviewCriterion } from './domain/entities/performance-review-criterion.entity';
import { PerformanceReviewResponse } from './domain/entities/performance-review-response.entity';
import { PerformanceReview } from './domain/entities/performance-review.entity';
import { PERFORMANCE_REVIEW_CRITERION_REPOSITORY } from './domain/repositories/performance-review-criterion-repository.interface';
import { PERFORMANCE_REVIEW_RESPONSE_REPOSITORY } from './domain/repositories/performance-review-response-repository.interface';
import { PERFORMANCE_REVIEW_REPOSITORY } from './domain/repositories/performance-review-repository.interface';
import { PerformanceReviewsController } from './presentation/performance-reviews.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      PerformanceReviewCriterion,
      PerformanceReview,
      PerformanceReviewResponse,
    ]),
    AuthenticationModule,
    EmployeeModule,
    NotificationsModule,
  ],
  controllers: [PerformanceReviewsController],
  providers: [
    PerformanceReviewsService,
    {
      provide: PERFORMANCE_REVIEW_CRITERION_REPOSITORY,
      useClass: TypeOrmPerformanceReviewCriterionRepository,
    },
    {
      provide: PERFORMANCE_REVIEW_REPOSITORY,
      useClass: TypeOrmPerformanceReviewRepository,
    },
    {
      provide: PERFORMANCE_REVIEW_RESPONSE_REPOSITORY,
      useClass: TypeOrmPerformanceReviewResponseRepository,
    },
  ],
  exports: [PerformanceReviewsService],
})
export class PerformanceReviewsModule {}
