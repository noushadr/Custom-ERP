import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/holidays/application/holiday_providers.dart';
import 'package:zera_erp/features/holidays/domain/entities/holiday.dart';
import 'package:zera_erp/features/holidays/domain/exceptions/holiday_exception.dart';
import 'package:zera_erp/features/holidays/domain/repositories/holiday_repository.dart';
import 'package:zera_erp/features/holidays/presentation/pages/holidays_page.dart';

import '../../helpers/fake_auth.dart';

class FakeHolidayRepository implements HolidayRepository {
  FakeHolidayRepository({
    this.holidays = const [],
    this.createResult,
    this.createError,
    this.updateResult,
    this.updateError,
    this.deleteError,
  });

  final List<Holiday> holidays;
  final Holiday? createResult;
  final Object? createError;
  final Holiday? updateResult;
  final Object? updateError;
  final Object? deleteError;

  ({String name, String date})? lastCreateInput;
  ({String id, String? name, String? date})? lastUpdateInput;
  String? lastDeleteId;

  @override
  Future<List<Holiday>> getAll({int? year}) async => holidays;

  @override
  Future<Holiday> create({required String name, required String date}) async {
    lastCreateInput = (name: name, date: date);
    if (createError != null) throw createError!;
    return createResult ?? Holiday(id: 'holiday-new', name: name, date: date);
  }

  @override
  Future<Holiday> update(String id, {String? name, String? date}) async {
    lastUpdateInput = (id: id, name: name, date: date);
    if (updateError != null) throw updateError!;
    return updateResult ??
        Holiday(id: id, name: name ?? 'Holiday', date: date ?? '2026-01-01');
  }

  @override
  Future<void> delete(String id) async {
    lastDeleteId = id;
    if (deleteError != null) throw deleteError!;
  }
}

Widget _app(FakeHolidayRepository repository) {
  final user = AuthUser(
    id: 'user-1',
    email: 'jane.doe@zeracreative.com',
    role: 'HR/Manager',
    permissions: const ['leave.manage'],
  );

  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(user)),
      ),
      holidayRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(home: HolidaysPage()),
  );
}

void main() {
  testWidgets('shows the list of holidays', (tester) async {
    final repository = FakeHolidayRepository(
      holidays: const [
        Holiday(id: 'holiday-1', name: 'Independence Day', date: '2026-08-14'),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Independence Day'), findsOneWidget);
    expect(find.text('Aug 14, 2026'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no holidays', (
    tester,
  ) async {
    await tester.pumpWidget(_app(FakeHolidayRepository()));
    await tester.pumpAndSettle();

    expect(find.text('No public holidays added yet.'), findsOneWidget);
  });

  testWidgets('editing a holiday pre-fills the form and saves the new name', (
    tester,
  ) async {
    final repository = FakeHolidayRepository(
      holidays: const [
        Holiday(id: 'holiday-1', name: 'Independence Day', date: '2026-08-14'),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Edit holiday'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Independence Day'),
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField), 'Independence Day (PK)');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repository.lastUpdateInput?.id, 'holiday-1');
    expect(repository.lastUpdateInput?.name, 'Independence Day (PK)');
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('deleting a holiday asks for confirmation before calling delete', (
    tester,
  ) async {
    final repository = FakeHolidayRepository(
      holidays: const [
        Holiday(id: 'holiday-1', name: 'Independence Day', date: '2026-08-14'),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Delete holiday?'), findsOneWidget);
    expect(repository.lastDeleteId, isNull);

    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(repository.lastDeleteId, 'holiday-1');
  });

  testWidgets('shows an error message when deleting fails', (tester) async {
    final repository = FakeHolidayRepository(
      holidays: const [
        Holiday(id: 'holiday-1', name: 'Independence Day', date: '2026-08-14'),
      ],
      deleteError: const HolidayException('Something went wrong.'),
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong.'), findsOneWidget);
  });
}
