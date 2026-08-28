import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/performance_reviews/application/performance_review_providers.dart';
import 'package:zera_erp/features/performance_reviews/presentation/pages/performance_reviews_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_performance_review.dart';

Future<void> _useTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app({
  AuthUser user = testAuthUser,
  FakePerformanceReviewRepository? performanceReviewRepository,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(user)),
      ),
      performanceReviewRepositoryProvider.overrideWithValue(
        performanceReviewRepository ?? FakePerformanceReviewRepository(),
      ),
    ],
    child: const MaterialApp(home: PerformanceReviewsPage()),
  );
}

const _hrUser = AuthUser(
  id: 'hr-1',
  email: 'hr@zeracreative.com',
  role: 'HR/Manager',
  permissions: ['performance.manage'],
);

void main() {
  testWidgets(
    'shows finalized reviews to a performance.manage holder',
    (tester) async {
      await _useTallSurface(tester);
      await tester.pumpWidget(
        _app(
          user: _hrUser,
          performanceReviewRepository: FakePerformanceReviewRepository(
            finalizedReviews: [
              buildTestPerformanceReview(
                id: 'review-1',
                employeeName: 'Jane Doe',
                reviewYear: 2,
                status: 'finalized',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Finalized Reviews'), findsOneWidget);
      expect(find.text('Year 2 Review — Jane Doe'), findsOneWidget);
    },
  );

  testWidgets(
    'shows pending reviews company-wide to a performance.manage holder',
    (tester) async {
      await _useTallSurface(tester);
      await tester.pumpWidget(
        _app(
          user: _hrUser,
          performanceReviewRepository: FakePerformanceReviewRepository(
            allPendingReviews: [
              buildTestPerformanceReview(
                id: 'review-1',
                employeeName: 'Ravi Report',
                reviewYear: 1,
                status: 'pending',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending Reviews'), findsOneWidget);
      expect(find.text('Year 1 Review — Ravi Report'), findsOneWidget);
    },
  );

  testWidgets(
    'shows an empty state when no reviews are pending',
    (tester) async {
      await _useTallSurface(tester);
      await tester.pumpWidget(_app(user: _hrUser));
      await tester.pumpAndSettle();

      expect(find.text('Pending Reviews'), findsOneWidget);
      expect(find.text('No reviews are pending right now.'), findsOneWidget);
    },
  );

  testWidgets(
    'hides the company-wide pending reviews section without performance.manage',
    (tester) async {
      await _useTallSurface(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Pending Reviews'), findsNothing);
    },
  );

  testWidgets(
    'shows an empty state when nothing has been finalized yet',
    (tester) async {
      await _useTallSurface(tester);
      await tester.pumpWidget(_app(user: _hrUser));
      await tester.pumpAndSettle();

      expect(find.text('Finalized Reviews'), findsOneWidget);
      expect(
        find.text('No reviews have been finalized yet.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'hides the finalized reviews section without performance.manage',
    (tester) async {
      await _useTallSurface(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Finalized Reviews'), findsNothing);
    },
  );
}
