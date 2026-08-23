import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/clients/application/clients_providers.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/knowledge_base/application/knowledge_base_providers.dart';
import 'package:zera_erp/features/leads/application/leads_providers.dart';
import 'package:zera_erp/features/leave/application/leave_providers.dart';
import 'package:zera_erp/features/notices/application/notice_providers.dart';
import 'package:zera_erp/features/notifications/application/notifications_providers.dart';
import 'package:zera_erp/features/payroll/application/payroll_providers.dart';
import 'package:zera_erp/features/performance_reviews/application/performance_review_providers.dart';
import 'package:zera_erp/features/requests/application/request_providers.dart';
import 'package:zera_erp/features/tasks/application/task_providers.dart';

import 'package:zera_erp/main.dart';
import 'helpers/fake_auth.dart';
import 'helpers/fake_clients.dart';
import 'helpers/fake_employee.dart';
import 'helpers/fake_knowledge_base.dart';
import 'helpers/fake_leads.dart';
import 'helpers/fake_leave.dart';
import 'helpers/fake_notice.dart';
import 'helpers/fake_notifications.dart';
import 'helpers/fake_payroll.dart';
import 'helpers/fake_performance_review.dart';
import 'helpers/fake_request.dart';
import 'helpers/fake_task.dart';

Future<void> _setSurfaceWidth(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _authenticatedApp({AuthUser? user}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(user ?? testAuthUser)),
      ),
      employeeRepositoryProvider.overrideWithValue(FakeEmployeeRepository()),
      noticeRepositoryProvider.overrideWithValue(FakeNoticeRepository()),
      requestRepositoryProvider.overrideWithValue(FakeRequestRepository()),
      leaveRepositoryProvider.overrideWithValue(FakeLeaveRepository()),
      performanceReviewRepositoryProvider.overrideWithValue(
        FakePerformanceReviewRepository(),
      ),
      knowledgeBaseRepositoryProvider.overrideWithValue(
        FakeKnowledgeBaseRepository(),
      ),
      taskRepositoryProvider.overrideWithValue(FakeTaskRepository()),
      clientsRepositoryProvider.overrideWithValue(FakeClientsRepository()),
      notificationsRepositoryProvider.overrideWithValue(
        FakeNotificationsRepository(),
      ),
      payrollRepositoryProvider.overrideWithValue(FakePayrollRepository()),
      leadsRepositoryProvider.overrideWithValue(FakeLeadsRepository()),
    ],
    child: const ZeraApp(),
  );
}

void main() {
  testWidgets('shows bottom navigation below the mobile breakpoint', (
    tester,
  ) async {
    await _setSurfaceWidth(tester, 480);
    await tester.pumpWidget(_authenticatedApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('shows a collapsed rail with labels at tablet width', (
    tester,
  ) async {
    await _setSurfaceWidth(tester, 800);
    await tester.pumpWidget(_authenticatedApp());
    await tester.pumpAndSettle();

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    expect(rail.labelType, NavigationRailLabelType.all);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('shows an extended sidebar at desktop width', (tester) async {
    await _setSurfaceWidth(tester, 1280);
    await tester.pumpWidget(_authenticatedApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('navRail')), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  group('grouped nav for Super Admin', () {
    const superAdmin = AuthUser(
      id: 'admin-1',
      email: 'admin@zeracreative.com',
      role: 'Super Admin',
      permissions: [
        'employees.manage',
        'clients.manage',
        'payroll.manage',
      ],
    );

    testWidgets(
      'shows the HR & admin and general section headings, ordered HR & '
      'admin above general, at desktop width — no admin-only group exists '
      'since Agency Reporting/Finances were removed',
      (tester) async {
        await _setSurfaceWidth(tester, 1280);
        await tester.pumpWidget(_authenticatedApp(user: superAdmin));
        await tester.pumpAndSettle();

        expect(find.text('ADMIN ONLY FEATURES'), findsNothing);
        expect(find.text('HR & ADMIN FEATURES'), findsOneWidget);
        expect(find.text('GENERAL FEATURES'), findsOneWidget);

        final navRail = find.byKey(const Key('navRail'));
        double topOf(String label) => tester
            .getTopLeft(
              find.descendant(of: navRail, matching: find.text(label)),
            )
            .dy;

        final hrAdminItemY = topOf('Clients & Projects');
        final generalItemY = topOf('Dashboard');
        expect(hrAdminItemY, lessThan(generalItemY));
      },
    );

    testWidgets(
      'does not show section headings for a non-Super-Admin role, even at '
      'desktop width',
      (tester) async {
        await _setSurfaceWidth(tester, 1280);
        await tester.pumpWidget(
          _authenticatedApp(
            user: const AuthUser(
              id: 'hr-1',
              email: 'hr@zeracreative.com',
              role: 'HR/Manager',
              permissions: [],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('ADMIN ONLY FEATURES'), findsNothing);
        expect(find.text('HR & ADMIN FEATURES'), findsNothing);
        expect(find.text('GENERAL FEATURES'), findsNothing);
      },
    );

    testWidgets(
      'does not show section headings at compact tablet width',
      (tester) async {
        await _setSurfaceWidth(tester, 800);
        await tester.pumpWidget(_authenticatedApp(user: superAdmin));
        await tester.pumpAndSettle();

        expect(find.text('ADMIN ONLY FEATURES'), findsNothing);
        expect(find.text('HR & ADMIN FEATURES'), findsNothing);
        expect(find.text('GENERAL FEATURES'), findsNothing);
      },
    );

    testWidgets(
      'shows section headings once the tablet rail is expanded',
      (tester) async {
        await _setSurfaceWidth(tester, 800);
        await tester.pumpWidget(_authenticatedApp(user: superAdmin));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();

        expect(find.text('ADMIN ONLY FEATURES'), findsNothing);
        expect(find.text('HR & ADMIN FEATURES'), findsOneWidget);
        expect(find.text('GENERAL FEATURES'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping a destination in the HR & Admin group switches to it',
      (tester) async {
        await _setSurfaceWidth(tester, 1280);
        await tester.pumpWidget(_authenticatedApp(user: superAdmin));
        await tester.pumpAndSettle();

        final navRail = find.byKey(const Key('navRail'));
        await tester.tap(
          find.descendant(of: navRail, matching: find.text('Payroll')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Payroll Runs'), findsOneWidget);
        expect(find.text('Invite Employee'), findsNothing);
      },
    );

    testWidgets(
      'tapping a destination in the general group switches to it',
      (tester) async {
        await _setSurfaceWidth(tester, 1280);
        await tester.pumpWidget(_authenticatedApp(user: superAdmin));
        await tester.pumpAndSettle();

        final navRail = find.byKey(const Key('navRail'));
        // Start on one general-group destination, then switch to another,
        // to exercise both halves of the selectedIndex round-trip.
        await tester.tap(
          find.descendant(of: navRail, matching: find.text('Dashboard')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: navRail, matching: find.text('Employees')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Invite Employee'), findsOneWidget);
      },
    );
  });
}
