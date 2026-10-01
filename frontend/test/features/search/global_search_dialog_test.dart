import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/search/application/search_providers.dart';
import 'package:zera_erp/features/search/domain/entities/search_result.dart';
import 'package:zera_erp/features/search/presentation/widgets/global_search_dialog.dart';

import '../../helpers/fake_search.dart';

Future<void> _pumpDialog(
  WidgetTester tester, {
  required FakeSearchRepository repository,
  ValueChanged<String>? onOpenEmployee,
  ValueChanged<String>? onOpenTask,
  ValueChanged<String>? onOpenProject,
  ValueChanged<String>? onOpenClient,
  ValueChanged<String>? onOpenArticle,
  ValueChanged<String>? onOpenLead,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [searchRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => GlobalSearchDialog(
                  onOpenEmployee: onOpenEmployee ?? (_) {},
                  onOpenTask: onOpenTask ?? (_) {},
                  onOpenProject: onOpenProject ?? (_) {},
                  onOpenClient: onOpenClient ?? (_) {},
                  onOpenArticle: onOpenArticle ?? (_) {},
                  onOpenLead: onOpenLead ?? (_) {},
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a hint until at least 2 characters are typed', (
    tester,
  ) async {
    await _pumpDialog(tester, repository: FakeSearchRepository());

    expect(find.text('Type at least 2 characters to search.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Type at least 2 characters to search.'), findsOneWidget);
  });

  testWidgets('shows categorized results grouped by type, debounced', (
    tester,
  ) async {
    final repository = FakeSearchRepository(
      results: const SearchResults(
        employees: [
          SearchResultItem(
            id: 'e1',
            title: 'Jane Doe',
            subtitle: 'Engineer',
            type: SearchResultType.employee,
          ),
        ],
        tasks: [
          SearchResultItem(
            id: 't1',
            title: 'Fix the login bug',
            subtitle: 'Jane Doe',
            type: SearchResultType.task,
          ),
        ],
        projects: [],
        clients: [],
        articles: [],
        leads: [],
      ),
    );

    await _pumpDialog(tester, repository: repository);

    await tester.enterText(find.byType(TextField), 'jane');
    // Before the debounce window elapses, no search has fired yet.
    expect(repository.lastQuery, isNull);

    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(repository.lastQuery, 'jane');
    expect(find.text('Employees'), findsOneWidget);
    // "Jane Doe" legitimately appears twice: once as the employee result's
    // own title, once as the task result's subtitle.
    expect(find.text('Jane Doe'), findsWidgets);
    expect(find.text('Engineer'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Fix the login bug'), findsOneWidget);
  });

  testWidgets('shows No results found for an empty match', (tester) async {
    await _pumpDialog(tester, repository: FakeSearchRepository());

    await tester.enterText(find.byType(TextField), 'nothing');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('No results found.'), findsOneWidget);
  });

  testWidgets('tapping a result closes the dialog and calls the matching '
      'callback', (tester) async {
    String? openedEmployeeId;
    final repository = FakeSearchRepository(
      results: const SearchResults(
        employees: [
          SearchResultItem(
            id: 'e1',
            title: 'Jane Doe',
            subtitle: null,
            type: SearchResultType.employee,
          ),
        ],
        tasks: [],
        projects: [],
        clients: [],
        articles: [],
        leads: [],
      ),
    );

    await _pumpDialog(
      tester,
      repository: repository,
      onOpenEmployee: (id) => openedEmployeeId = id,
    );

    await tester.enterText(find.byType(TextField), 'jane');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jane Doe'));
    await tester.pumpAndSettle();

    expect(openedEmployeeId, 'e1');
    expect(find.byType(GlobalSearchDialog), findsNothing);
  });
}
