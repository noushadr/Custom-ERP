import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/agency_reporting/application/agency_reporting_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/automations/application/automations_providers.dart';
import 'package:zera_erp/features/clients/application/clients_providers.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/finances/application/finances_providers.dart';
import 'package:zera_erp/features/knowledge_base/application/knowledge_base_providers.dart';
import 'package:zera_erp/features/leave/application/leave_providers.dart';
import 'package:zera_erp/features/notices/application/notice_providers.dart';
import 'package:zera_erp/features/notifications/application/notifications_providers.dart';
import 'package:zera_erp/features/performance_reviews/application/performance_review_providers.dart';
import 'package:zera_erp/features/requests/application/request_providers.dart';
import 'package:zera_erp/features/tasks/application/task_providers.dart';

import 'package:zera_erp/main.dart';
import 'helpers/fake_agency_reporting.dart';
import 'helpers/fake_auth.dart';
import 'helpers/fake_automations.dart';
import 'helpers/fake_clients.dart';
import 'helpers/fake_employee.dart';
import 'helpers/fake_finances.dart';
import 'helpers/fake_knowledge_base.dart';
import 'helpers/fake_leave.dart';
import 'helpers/fake_notice.dart';
import 'helpers/fake_notifications.dart';
import 'helpers/fake_performance_review.dart';
import 'helpers/fake_request.dart';
import 'helpers/fake_task.dart';

Future<void> _setSurfaceWidth(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _authenticatedApp() {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(const AuthAuthenticated(testAuthUser)),
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
      agencyReportingRepositoryProvider.overrideWithValue(
        FakeAgencyReportingRepository(),
      ),
      financesRepositoryProvider.overrideWithValue(FakeFinancesRepository()),
      notificationsRepositoryProvider.overrideWithValue(
        FakeNotificationsRepository(),
      ),
      automationsRepositoryProvider.overrideWithValue(
        FakeAutomationsRepository(),
      ),
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

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
