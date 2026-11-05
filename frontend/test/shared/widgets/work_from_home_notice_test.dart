import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/announcements/application/announcement_providers.dart';
import 'package:zera_erp/features/announcements/domain/entities/today_announcements.dart';
import 'package:zera_erp/shared/widgets/work_from_home_notice.dart';

import '../../helpers/fake_announcements.dart';

Widget _app(TodayWorkFromHome? wfh) {
  return ProviderScope(
    overrides: [
      announcementsRepositoryProvider.overrideWithValue(
        FakeAnnouncementsRepository(
          today: TodayAnnouncements(
            birthdays: const [],
            workAnniversaries: const [],
            holiday: null,
            notices: const [],
            employeeOfTheMonth: null,
            workFromHome: wfh,
          ),
        ),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: WorkFromHomeNotice())),
  );
}

void main() {
  group('workFromHomeMessages', () {
    test('says nothing when there is no work-from-home day', () {
      expect(workFromHomeMessages(null), isEmpty);
    });

    test('words a company day, with its reason', () {
      expect(
        workFromHomeMessages(
          const TodayWorkFromHome(
            today: TodayWfhNotice(personal: false, note: 'Power cut'),
          ),
        ),
        ['Today is a work-from-home day — Power cut'],
      );
    });

    test('words a personal day, and tomorrow separately', () {
      expect(
        workFromHomeMessages(
          const TodayWorkFromHome(
            today: TodayWfhNotice(personal: true),
            tomorrow: TodayWfhNotice(personal: false),
          ),
        ),
        ["You're working from home today", 'Tomorrow is a work-from-home day'],
      );
    });
  });

  testWidgets('the dashboard notice shows a work-from-home day', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const TodayWorkFromHome(
          today: TodayWfhNotice(personal: false, note: 'Power cut'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('work-from-home-notice')), findsOneWidget);
    expect(
      find.text('Today is a work-from-home day — Power cut'),
      findsOneWidget,
    );
  });

  testWidgets('the dashboard notice is absent when there is no such day', (
    tester,
  ) async {
    await tester.pumpWidget(_app(null));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('work-from-home-notice')), findsNothing);
  });
}
