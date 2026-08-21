import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/employee.dart';
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
  testWidgets(
    'a manager viewing a pending review can rate and complete it',
    (tester) async {
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
    },
  );

  testWidgets(
    "the review's own employee sees read-only ratings but can save a self-assessment",
    (tester) async {
      final review = buildTestPerformanceReview(
        employeeId: 'employee-1',
        status: 'pending',
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

      await tester.enterText(
        find.byType(TextField).first,
        'Had a great year!',
      );
      await tester.tap(find.text('Save Comments'));
      await tester.pumpAndSettle();

      expect(repository.lastSelfAssessmentReviewId, 'review-1');
      expect(repository.lastSelfAssessmentComments, 'Had a great year!');
    },
  );

  testWidgets('HR/Admin can finalize a completed review', (tester) async {
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

    expect(find.text('Finalize'), findsOneWidget);

    await tester.tap(find.text('Finalize'));
    await tester.pumpAndSettle();

    expect(repository.lastFinalizedReviewId, 'review-1');
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
