import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/attendance/application/attendance_providers.dart';
import 'package:zera_erp/features/attendance/domain/entities/attendance.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/holidays/application/holiday_providers.dart';
import 'package:zera_erp/features/leave/application/leave_providers.dart';
import 'package:zera_erp/features/leave/presentation/widgets/leave_calendar_view.dart';

import '../../helpers/fake_attendance.dart';
import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_holiday.dart';
import '../../helpers/fake_leave.dart';

void main() {
  testWidgets('the calendar marks public holidays and work-from-home days', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    String iso(int day) =>
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) =>
                PresetAuthController(const AuthAuthenticated(testAuthUser)),
          ),
          leaveRepositoryProvider.overrideWithValue(FakeLeaveRepository()),
          employeeRepositoryProvider.overrideWithValue(
            FakeEmployeeRepository(),
          ),
          holidayRepositoryProvider.overrideWithValue(
            FakeHolidayRepository(
              holidays: [buildTestHoliday(name: 'Eid Day', date: iso(10))],
            ),
          ),
          attendanceRepositoryProvider.overrideWithValue(
            FakeAttendanceRepository(
              wfhDays: [
                WfhDay(date: iso(12), note: 'Power cut', presentCount: 0),
              ],
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LeaveCalendarView(initialScope: 'company'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calendar-holiday')), findsOneWidget);
    expect(find.text('Eid Day'), findsOneWidget);
    expect(find.byKey(const Key('calendar-wfh')), findsOneWidget);
    expect(find.text('WFH'), findsOneWidget);

    Color? cellColor(int day) {
      final box = tester.widget<Container>(
        find
            .ancestor(
              of: find.byKey(Key('leave-day-$day')),
              matching: find.byType(Container),
            )
            .first,
      );
      return (box.decoration as BoxDecoration).color;
    }

    // The holiday and every Saturday/Sunday are grey; an ordinary weekday
    // is not.
    expect(cellColor(10), isNotNull);
    final sunday = DateTime(
      now.year,
      now.month,
      1,
    ).add(Duration(days: (7 - DateTime(now.year, now.month, 1).weekday) % 7));
    expect(cellColor(sunday.day), isNotNull);
    final weekday = List.generate(28, (i) => i + 1).firstWhere((d) {
      final w = DateTime(now.year, now.month, d).weekday;
      return w <= 5 && d != 10 && d != 12;
    });
    expect(cellColor(weekday), isNull);
  });
}
