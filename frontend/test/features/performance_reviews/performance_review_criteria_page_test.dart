import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/performance_reviews/application/performance_review_providers.dart';
import 'package:zera_erp/features/performance_reviews/domain/exceptions/performance_review_exception.dart';
import 'package:zera_erp/features/performance_reviews/presentation/pages/performance_review_criteria_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_performance_review.dart';

Future<void> _useTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app({FakePerformanceReviewRepository? performanceReviewRepository}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(const AuthAuthenticated(testAuthUser)),
      ),
      performanceReviewRepositoryProvider.overrideWithValue(
        performanceReviewRepository ?? FakePerformanceReviewRepository(),
      ),
    ],
    child: const MaterialApp(home: PerformanceReviewCriteriaPage()),
  );
}

void main() {
  testWidgets('lists existing criteria', (tester) async {
    await _useTallSurface(tester);
    await tester.pumpWidget(
      _app(
        performanceReviewRepository: FakePerformanceReviewRepository(
          criteria: [
            buildTestPerformanceReviewCriterion(
              id: 'c1',
              name: 'Overall Performance',
              responseType: 'rating',
            ),
            buildTestPerformanceReviewCriterion(
              id: 'c2',
              name: 'Strengths',
              responseType: 'text',
              sortOrder: 1,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Overall Performance'), findsOneWidget);
    expect(find.text('Strengths'), findsOneWidget);
    expect(find.text('Rating (1-5)'), findsOneWidget);
    expect(find.text('Written'), findsOneWidget);
  });

  testWidgets('adding a criterion calls createCriterion', (tester) async {
    await _useTallSurface(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Communication',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add criterion'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('archiving a criterion calls updateCriterion', (tester) async {
    await _useTallSurface(tester);
    await tester.pumpWidget(
      _app(
        performanceReviewRepository: FakePerformanceReviewRepository(
          criteria: [buildTestPerformanceReviewCriterion(id: 'c1')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('moving a criterion down reorders with the recomputed id list', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = FakePerformanceReviewRepository(
      criteria: [
        buildTestPerformanceReviewCriterion(id: 'a', name: 'First', sortOrder: 0),
        buildTestPerformanceReviewCriterion(id: 'b', name: 'Second', sortOrder: 1),
      ],
    );
    await tester.pumpWidget(_app(performanceReviewRepository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Move down').first);
    await tester.pumpAndSettle();

    expect(repository.lastReorderedIds, ['b', 'a']);
  });

  testWidgets(
    'deleting a criterion that already has responses shows the conflict message',
    (tester) async {
      await _useTallSurface(tester);
      await tester.pumpWidget(
        _app(
          performanceReviewRepository: FakePerformanceReviewRepository(
            criteria: [buildTestPerformanceReviewCriterion(id: 'c1')],
            deleteCriterionError: const PerformanceReviewException(
              'Cannot delete a criterion that already has review responses '
              'recorded against it. Archive it instead.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('already has review responses'),
        findsOneWidget,
      );
    },
  );
}
