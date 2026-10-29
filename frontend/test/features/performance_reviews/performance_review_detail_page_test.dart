import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/employee.dart';
import 'package:zera_erp/features/employee/presentation/pages/employee_profile_page.dart';
import 'package:zera_erp/features/performance_reviews/application/performance_review_providers.dart';
import 'package:zera_erp/features/performance_reviews/presentation/pages/performance_review_detail_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_performance_review.dart';

Future<void> _useTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app({
  required Employee viewerProfile,
  required FakePerformanceReviewRepository performanceReviewRepository,
  List<String> permissions = const [],
}) {
  final user = AuthUser(
    id: 'viewer-user',
    email: viewerProfile.email,
    role: 'Employee',
    permissions: permissions,
  );

  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(user)),
      ),
      employeeRepositoryProvider.overrideWithValue(
        FakeEmployeeRepository(me: viewerProfile),
      ),
      performanceReviewRepositoryProvider.overrideWithValue(
        performanceReviewRepository,
      ),
    ],
    child: const MaterialApp(
      home: PerformanceReviewDetailPage(reviewId: 'review-1'),
    ),
  );
}

void main() {
  testWidgets('a manager viewing a pending review can rate and complete it', (
    tester,
  ) async {
    final review = buildTestPerformanceReview(
      status: 'pending',
      responses: [
        buildTestPerformanceReviewResponse(
          id: 'r1',
          criterionName: 'Overall Performance',
          responseType: 'rating',
        ),
      ],
    );
    final repository = FakePerformanceReviewRepository(reviewById: review);

    await _useTallSurface(tester);
    await tester.pumpWidget(
      _app(
        // The manager's own profile, distinct from the review's employee.
        viewerProfile: buildTestEmployee(id: 'manager-1'),
        performanceReviewRepository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Overall Performance'), findsOneWidget);
    expect(find.text('Complete Review'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star_border).at(2));
    await tester.tap(find.text('Complete Review'));
    await tester.pumpAndSettle();

    expect(repository.lastCompletedReviewId, 'review-1');
    expect(repository.lastCompletedResponses!.single.ratingValue, 3);
  });

  testWidgets(
    "the review's own employee sees read-only ratings but can save a self-assessment",
    (tester) async {
      final review = buildTestPerformanceReview(
        employeeId: 'employee-1',
        status: 'completed',
        completedByName: 'Sam Manager',
      );
      final repository = FakePerformanceReviewRepository(reviewById: review);

      await _useTallSurface(tester);
      await tester.pumpWidget(
        _app(
          viewerProfile: buildTestEmployee(id: 'employee-1'),
          performanceReviewRepository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Complete Review'), findsNothing);
      final starButton = tester.widget<IconButton>(
        find
            .ancestor(
              of: find.byIcon(Icons.star_border).first,
              matching: find.byType(IconButton),
            )
            .first,
      );
      expect(starButton.onPressed, isNull);

      await tester.enterText(find.byType(TextField).last, 'Had a great year!');
      expect(
        find.textContaining('filled in by management (Sam Manager)'),
        findsOneWidget,
      );
      expect(find.text('Employee Feedback (required)'), findsOneWidget);
      await tester.ensureVisible(find.text('Submit Feedback'));
      await tester.tap(find.text('Submit Feedback'));
      await tester.pumpAndSettle();

      expect(repository.lastSelfAssessmentReviewId, 'review-1');
      expect(repository.lastSelfAssessmentComments, 'Had a great year!');
    },
  );

  testWidgets(
    'the evaluation form groups criteria by section and submits comments '
    'and the overall rating',
    (tester) async {
      final review = buildTestPerformanceReview(
        status: 'pending',
        responses: [
          buildTestPerformanceReviewResponse(
            id: 'r1',
            criterionName: 'Quality of Work',
            section: 'Performance Overview',
            hasComment: true,
          ),
          buildTestPerformanceReviewResponse(
            id: 'r2',
            criterionName: 'Strengths',
            responseType: 'text',
            sortOrder: 1,
          ),
        ],
      );
      final repository = FakePerformanceReviewRepository(reviewById: review);

      await _useTallSurface(tester);
      await tester.pumpWidget(
        _app(
          viewerProfile: buildTestEmployee(id: 'manager-1'),
          performanceReviewRepository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Employee Information'), findsOneWidget);
      expect(find.text('Performance Overview'), findsOneWidget);
      expect(find.text('Overall Performance Rating'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Comments'),
        'Solid work',
      );
      await tester.tap(find.byIcon(Icons.star_border).at(3));
      await tester.tap(find.text('Meets Expectations'));
      await tester.pump();
      await tester.ensureVisible(find.text('Complete Review'));
      await tester.tap(find.text('Complete Review'));
      await tester.pumpAndSettle();

      final r1 = repository.lastCompletedResponses!.firstWhere(
        (r) => r.responseId == 'r1',
      );
      expect(r1.ratingValue, 4);
      expect(r1.commentValue, 'Solid work');
      final fields = repository.lastCompletedFields!;
      expect(fields.overallRating, 'meets_expectations');
      expect(find.text('Date of Evaluation'), findsNothing);
    },
  );

  testWidgets('Save Draft saves answers without completing the review', (
    tester,
  ) async {
    final review = buildTestPerformanceReview(
      status: 'pending',
      responses: [
        buildTestPerformanceReviewResponse(
          id: 'r1',
          section: 'Performance Overview',
        ),
      ],
    );
    final repository = FakePerformanceReviewRepository(reviewById: review);

    await _useTallSurface(tester);
    await tester.pumpWidget(
      _app(
        viewerProfile: buildTestEmployee(id: 'manager-1'),
        performanceReviewRepository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Save Draft'), findsOneWidget);
    expect(find.text('Complete Review'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star_border).at(1));
    await tester.pump();
    await tester.ensureVisible(find.text('Save Draft'));
    await tester.tap(find.text('Save Draft'));
    await tester.pumpAndSettle();

    expect(repository.lastDraftReviewId, 'review-1');
    expect(repository.lastDraftResponses!.single.ratingValue, 2);
    expect(repository.lastCompletedReviewId, isNull);
  });

  testWidgets(
    'shows the date of evaluation only once the review is submitted',
    (tester) async {
      final review = buildTestPerformanceReview(
        status: 'completed',
        completedAt: DateTime.utc(2026, 12, 3, 10),
      );
      final repository = FakePerformanceReviewRepository(reviewById: review);

      await _useTallSurface(tester);
      await tester.pumpWidget(
        _app(
          viewerProfile: buildTestEmployee(id: 'hr-1'),
          performanceReviewRepository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Date of Evaluation'), findsOneWidget);
      expect(find.text('Dec 03, 2026'), findsOneWidget);
    },
  );

  testWidgets(
    'explains why employee feedback is not editable, and the name opens '
    'the employee profile',
    (tester) async {
      final review = buildTestPerformanceReview(
        employeeId: 'employee-1',
        status: 'pending',
      );
      final repository = FakePerformanceReviewRepository(reviewById: review);

      await _useTallSurface(tester);
      await tester.pumpWidget(
        _app(
          viewerProfile: buildTestEmployee(id: 'manager-1'),
          performanceReviewRepository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('only after you complete it'), findsOneWidget);

      await tester.tap(
        find
            .descendant(
              of: find.byType(InkWell),
              matching: find.text(review.employeeName),
            )
            .first,
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(EmployeeProfilePage), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
      expect(find.byType(EmployeeProfilePage), findsOneWidget);
    },
  );

  testWidgets('feedback is mandatory: an empty submit is blocked', (
    tester,
  ) async {
    final review = buildTestPerformanceReview(
      employeeId: 'employee-1',
      status: 'completed',
    );
    final repository = FakePerformanceReviewRepository(reviewById: review);

    await _useTallSurface(tester);
    await tester.pumpWidget(
      _app(
        viewerProfile: buildTestEmployee(id: 'employee-1'),
        performanceReviewRepository: repository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Submit Feedback'));
    await tester.tap(find.text('Submit Feedback'));
    await tester.pumpAndSettle();

    expect(find.text('Your feedback is required.'), findsOneWidget);
    expect(repository.lastSelfAssessmentReviewId, isNull);
  });

  testWidgets(
    'HR/Admin cannot finalize until the employee has given feedback',
    (tester) async {
      final review = buildTestPerformanceReview(status: 'completed');
      final repository = FakePerformanceReviewRepository(reviewById: review);

      await _useTallSurface(tester);
      await tester.pumpWidget(
        _app(
          viewerProfile: buildTestEmployee(id: 'hr-1'),
          performanceReviewRepository: repository,
          permissions: const ['performance.manage'],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Finalize'), findsNothing);
      expect(
        find.textContaining('required before it can be finalized'),
        findsOneWidget,
      );
    },
  );

  testWidgets('HR/Admin can finalize a completed review', (tester) async {
    final review = buildTestPerformanceReview(
      status: 'completed',
      employeeComments: 'Thanks for the review',
    );
    final repository = FakePerformanceReviewRepository(reviewById: review);

    await _useTallSurface(tester);
    await tester.pumpWidget(
      _app(
        viewerProfile: buildTestEmployee(id: 'hr-1'),
        performanceReviewRepository: repository,
        permissions: const ['performance.manage'],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Finalize'), findsOneWidget);

    await tester.tap(find.text('Finalize'));
    await tester.pumpAndSettle();

    expect(repository.lastFinalizedReviewId, 'review-1');
  });

  testWidgets('HR/Admin can unfinalize a finalized review', (tester) async {
    final review = buildTestPerformanceReview(
      status: 'finalized',
      finalizedByName: 'HR Person',
    );
    final repository = FakePerformanceReviewRepository(reviewById: review);

    await _useTallSurface(tester);
    await tester.pumpWidget(
      _app(
        viewerProfile: buildTestEmployee(id: 'hr-1'),
        performanceReviewRepository: repository,
        permissions: const ['performance.manage'],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unfinalize'), findsOneWidget);
    expect(find.text('Finalize'), findsNothing);

    await tester.tap(find.text('Unfinalize'));
    await tester.pumpAndSettle();

    expect(repository.lastUnfinalizedReviewId, 'review-1');
  });

  testWidgets('a finalized review shows no action buttons', (tester) async {
    final review = buildTestPerformanceReview(
      employeeId: 'employee-1',
      status: 'finalized',
      completedByName: 'Manager Person',
      finalizedByName: 'HR Person',
    );
    final repository = FakePerformanceReviewRepository(reviewById: review);

    await _useTallSurface(tester);
    await tester.pumpWidget(
      _app(
        viewerProfile: buildTestEmployee(id: 'employee-1'),
        performanceReviewRepository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Complete Review'), findsNothing);
    expect(find.text('Save Changes'), findsNothing);
    expect(find.text('Finalize'), findsNothing);
    expect(find.text('Save Comments'), findsNothing);
    expect(find.textContaining('Completed by Manager Person'), findsOneWidget);
    expect(find.textContaining('Finalized by HR Person'), findsOneWidget);
  });
}
