import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/clients/application/clients_providers.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/employee.dart';
import 'package:zera_erp/features/employee/domain/entities/payroll_summary.dart';
import 'package:zera_erp/features/freelancers/application/freelancers_providers.dart';
import 'package:zera_erp/features/knowledge_base/application/knowledge_base_providers.dart';
import 'package:zera_erp/features/leads/application/leads_providers.dart';
import 'package:zera_erp/features/leave/application/leave_providers.dart';
import 'package:zera_erp/features/notices/application/notice_providers.dart';
import 'package:zera_erp/features/notifications/application/notifications_providers.dart';
import 'package:zera_erp/features/payroll/application/payroll_providers.dart';
import 'package:zera_erp/features/performance_reviews/application/performance_review_providers.dart';
import 'package:zera_erp/features/requests/application/request_providers.dart';
import 'package:zera_erp/features/tasks/application/task_providers.dart';
import 'package:zera_erp/features/tasks/domain/entities/task_status.dart';
import 'package:zera_erp/shared/widgets/metric_card.dart';

import 'package:zera_erp/main.dart';
import 'helpers/fake_auth.dart';
import 'helpers/fake_clients.dart';
import 'helpers/fake_employee.dart';
import 'helpers/fake_freelancers.dart';
import 'helpers/fake_knowledge_base.dart';
import 'helpers/fake_leads.dart';
import 'helpers/fake_leave.dart';
import 'helpers/fake_notice.dart';
import 'helpers/fake_notifications.dart';
import 'helpers/fake_payroll.dart';
import 'helpers/fake_performance_review.dart';
import 'helpers/fake_request.dart';
import 'helpers/fake_task.dart';

Widget _authenticatedApp({
  AuthUser user = testAuthUser,
  List<Employee>? employees,
  PayrollSummary? payrollSummary,
  FakePerformanceReviewRepository? performanceReviewRepository,
  FakeEmployeeRepository? employeeRepository,
  FakeRequestRepository? requestRepository,
  FakeTaskRepository? taskRepository,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(user)),
      ),
      employeeRepositoryProvider.overrideWithValue(
        employeeRepository ??
            FakeEmployeeRepository(
              employees: employees ?? [buildTestEmployee()],
              payrollSummary: payrollSummary,
            ),
      ),
      noticeRepositoryProvider.overrideWithValue(FakeNoticeRepository()),
      requestRepositoryProvider.overrideWithValue(
        requestRepository ?? FakeRequestRepository(),
      ),
      leaveRepositoryProvider.overrideWithValue(FakeLeaveRepository()),
      performanceReviewRepositoryProvider.overrideWithValue(
        performanceReviewRepository ?? FakePerformanceReviewRepository(),
      ),
      knowledgeBaseRepositoryProvider.overrideWithValue(
        FakeKnowledgeBaseRepository(),
      ),
      taskRepositoryProvider.overrideWithValue(
        taskRepository ?? FakeTaskRepository(),
      ),
      clientsRepositoryProvider.overrideWithValue(FakeClientsRepository()),
      notificationsRepositoryProvider.overrideWithValue(
        FakeNotificationsRepository(),
      ),
      payrollRepositoryProvider.overrideWithValue(FakePayrollRepository()),
      freelancersRepositoryProvider.overrideWithValue(
        FakeFreelancersRepository(),
      ),
      leadsRepositoryProvider.overrideWithValue(FakeLeadsRepository()),
    ],
    child: const ZeraApp(),
  );
}

/// The numbered badge count shown on a nav destination's icon (via
/// ResponsiveScaffold's `_railIcon`), or null if that destination has no
/// badge right now — read directly off the constructed `NavigationRail`
/// rather than searching rendered text, since bare digits elsewhere on the
/// page (metric tiles, counts) would otherwise collide.
int? _badgeCountFor(WidgetTester tester, String label) {
  final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
  for (final destination in rail.destinations) {
    final labelWidget = destination.label;
    if (labelWidget is Text && labelWidget.data == label) {
      final icon = destination.icon;
      if (icon is Badge && icon.label is Text) {
        return int.tryParse((icon.label as Text).data ?? '');
      }
      return null;
    }
  }
  return null;
}

void main() {
  testWidgets('renders the user dashboard by default for a plain employee', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_authenticatedApp());
    await tester.pumpAndSettle();

    expect(find.text('Company Notices'), findsOneWidget);
    expect(find.text('Team Members'), findsOneWidget);
  });

  testWidgets('renders the admin dashboard stats for a Super Admin', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _authenticatedApp(
        user: const AuthUser(
          id: 'admin-1',
          email: 'admin@zeracreative.com',
          role: 'Super Admin',
          permissions: [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total Employees'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets(
    'admin dashboard Work Mode tiles only count active employees',
    (WidgetTester tester) async {
      const admin = AuthUser(
        id: 'admin-1',
        email: 'admin@zeracreative.com',
        role: 'Super Admin',
        permissions: [],
      );
      await tester.pumpWidget(
        _authenticatedApp(
          user: admin,
          employees: [
            buildTestEmployee(
              id: 'employee-1',
              employmentStatus: 'active',
              workMode: 'remote',
            ),
            buildTestEmployee(
              id: 'employee-2',
              employmentStatus: 'resigned',
              workMode: 'remote',
            ),
            buildTestEmployee(
              id: 'employee-3',
              employmentStatus: 'terminated',
              workMode: 'hybrid',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final onSiteCard = tester.widget<MetricCard>(
        find.byWidgetPredicate((w) => w is MetricCard && w.label == 'On-site'),
      );
      final remoteCard = tester.widget<MetricCard>(
        find.byWidgetPredicate((w) => w is MetricCard && w.label == 'Remote'),
      );
      final hybridCard = tester.widget<MetricCard>(
        find.byWidgetPredicate((w) => w is MetricCard && w.label == 'Hybrid'),
      );

      // Only employee-1 is active, so Remote reads 1 (not 2) and Hybrid
      // reads 0 since its only member has left.
      expect(onSiteCard.value, '0');
      expect(remoteCard.value, '1');
      expect(hybridCard.value, '0');
    },
  );

  testWidgets(
    'admin dashboard shows monthly and daily payroll for an employees.manage holder',
    (WidgetTester tester) async {
      const admin = AuthUser(
        id: 'admin-1',
        email: 'admin@zeracreative.com',
        role: 'Super Admin',
        permissions: ['employees.manage'],
      );
      await tester.pumpWidget(
        _authenticatedApp(
          user: admin,
          payrollSummary: const PayrollSummary(
            totalMonthlyPayroll: 250000,
            dailyPayroll: 8333.33,
            activeEmployeeCount: 4,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Not asserting on bare 'Payroll' here — the Admin Business
      // Management "Payroll" nav item (Module 6) also renders that exact
      // text for this Super Admin, so it's no longer unique to this
      // dashboard section's own heading.
      expect(find.text('Monthly Payroll'), findsOneWidget);
      expect(find.text('PKR 250,000'), findsOneWidget);
      expect(find.text('≈ \$899'), findsOneWidget);
      expect(find.text('Daily Payroll'), findsOneWidget);
      expect(find.text('PKR 8,333'), findsOneWidget);
      expect(find.text('≈ \$29'), findsOneWidget);
      expect(find.text('Average Salary'), findsOneWidget);
      expect(find.text('PKR 62,500'), findsOneWidget);
      expect(find.text('≈ \$224'), findsOneWidget);
    },
  );

  testWidgets(
    'hides the payroll stats from an admin dashboard viewer without employees.manage',
    (WidgetTester tester) async {
      const admin = AuthUser(
        id: 'admin-1',
        email: 'admin@zeracreative.com',
        role: 'Super Admin',
        permissions: [],
      );
      await tester.pumpWidget(_authenticatedApp(user: admin));
      await tester.pumpAndSettle();

      expect(find.text('Monthly Payroll'), findsNothing);
    },
  );

  testWidgets(
    'admin dashboard shows the pending performance reviews count for a performance.manage holder',
    (WidgetTester tester) async {
      const admin = AuthUser(
        id: 'admin-1',
        email: 'admin@zeracreative.com',
        role: 'Super Admin',
        permissions: ['performance.manage'],
      );
      await tester.pumpWidget(
        _authenticatedApp(
          user: admin,
          performanceReviewRepository: FakePerformanceReviewRepository(
            allPendingReviews: [
              buildTestPerformanceReview(id: 'review-1'),
              buildTestPerformanceReview(id: 'review-2'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending Performance Reviews'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    },
  );

  testWidgets(
    'hides the pending performance reviews stat from an admin dashboard viewer without performance.manage',
    (WidgetTester tester) async {
      const admin = AuthUser(
        id: 'admin-1',
        email: 'admin@zeracreative.com',
        role: 'Super Admin',
        permissions: [],
      );
      await tester.pumpWidget(_authenticatedApp(user: admin));
      await tester.pumpAndSettle();

      expect(find.text('Pending Performance Reviews'), findsNothing);
    },
  );

  testWidgets('switching destinations updates the body', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_authenticatedApp());

    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();

    expect(find.text('My Requests'), findsOneWidget);
  });

  testWidgets(
    'hides Employees and Settings from the nav for a plain employee',
    (WidgetTester tester) async {
      await tester.pumpWidget(_authenticatedApp());
      await tester.pumpAndSettle();

      expect(find.text('Employees'), findsNothing);
      expect(find.text('Settings'), findsNothing);
    },
  );

  testWidgets(
    'shows Employees and Settings in the nav for a Super Admin',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _authenticatedApp(
          user: const AuthUser(
            id: 'admin-1',
            email: 'admin@zeracreative.com',
            role: 'Super Admin',
            permissions: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Employees'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    },
  );

  testWidgets(
    'shows Clients & Projects in the nav for a Super Admin',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _authenticatedApp(
          user: const AuthUser(
            id: 'admin-1',
            email: 'admin@zeracreative.com',
            role: 'Super Admin',
            permissions: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clients & Projects'), findsOneWidget);
    },
  );

  testWidgets(
    'shows Clients & Projects in the nav for HR/Manager too',
    (WidgetTester tester) async {
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

      // HR/Manager shares Clients & Projects with Super Admin.
      expect(find.text('Employees'), findsOneWidget);
      expect(find.text('Clients & Projects'), findsOneWidget);
    },
  );

  testWidgets(
    'hides Clients & Projects from the nav for a plain employee',
    (WidgetTester tester) async {
      await tester.pumpWidget(_authenticatedApp());
      await tester.pumpAndSettle();

      expect(find.text('Clients & Projects'), findsNothing);
    },
  );

  testWidgets(
    'shows Payroll in the nav for a Super Admin',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _authenticatedApp(
          user: const AuthUser(
            id: 'admin-1',
            email: 'admin@zeracreative.com',
            role: 'Super Admin',
            permissions: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payroll'), findsOneWidget);
    },
  );

  testWidgets(
    'shows Payroll in the nav for HR/Manager too',
    (WidgetTester tester) async {
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

      expect(find.text('Employees'), findsOneWidget);
      expect(find.text('Payroll'), findsOneWidget);
    },
  );

  testWidgets(
    'hides Payroll from the nav for a plain employee',
    (WidgetTester tester) async {
      await tester.pumpWidget(_authenticatedApp());
      await tester.pumpAndSettle();

      expect(find.text('Payroll'), findsNothing);
    },
  );

  testWidgets(
    'shows Admin Business Management stats for a holder of every module '
    'permission',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _authenticatedApp(
          user: const AuthUser(
            id: 'admin-1',
            email: 'admin@zeracreative.com',
            role: 'Super Admin',
            permissions: [
              'clients.manage',
              'payroll.manage',
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Admin Business Management'), findsOneWidget);
      expect(find.text('Active Projects'), findsOneWidget);
      expect(find.text('Clients At Risk'), findsOneWidget);
      expect(find.text('Latest Payroll Run'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Total Freelancers'), findsOneWidget);
    },
  );

  testWidgets(
    'hides Admin Business Management stats from an admin dashboard viewer '
    'without any of those permissions',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _authenticatedApp(
          user: const AuthUser(
            id: 'admin-1',
            email: 'admin@zeracreative.com',
            role: 'Super Admin',
            permissions: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Admin Business Management'), findsNothing);
      expect(find.text('Active Projects'), findsNothing);
      expect(find.text('Latest Payroll Run'), findsNothing);
      expect(find.text('Total Freelancers'), findsNothing);
    },
  );

  testWidgets(
    'a Super Admin sees only Dashboard, never User Dashboard',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _authenticatedApp(
          user: const AuthUser(
            id: 'admin-1',
            email: 'admin@zeracreative.com',
            role: 'Super Admin',
            permissions: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('User Dashboard'), findsNothing);
      expect(find.text('Total Employees'), findsOneWidget);
    },
  );

  testWidgets(
    'a plain employee sees only User Dashboard, never Dashboard',
    (WidgetTester tester) async {
      await tester.pumpWidget(_authenticatedApp());
      await tester.pumpAndSettle();

      expect(find.text('User Dashboard'), findsWidgets);
      expect(find.text('Dashboard'), findsNothing);
      expect(find.text('Total Employees'), findsNothing);
    },
  );

  group('nav badges', () {
    testWidgets(
      'badges Requests with the sum of open requests and manager approvals',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _authenticatedApp(
            requestRepository: FakeRequestRepository(
              mine: [
                buildTestRequest(id: 'mine-open', status: 'submitted'),
                buildTestRequest(id: 'mine-done', status: 'completed'),
              ],
              pendingManagerApproval: [
                buildTestRequest(id: 'manager-1'),
                buildTestRequest(id: 'manager-2'),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(_badgeCountFor(tester, 'Requests'), 3);
      },
    );

    testWidgets('shows no Requests badge when nothing is open', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _authenticatedApp(
          requestRepository: FakeRequestRepository(
            mine: [buildTestRequest(status: 'completed')],
          ),
          employeeRepository: FakeEmployeeRepository(
            me: buildTestEmployee(profileCompletionPercentage: 100),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_badgeCountFor(tester, 'Requests'), isNull);
    });

    testWidgets(
      'badges Tasks with the count of tasks not completed or cancelled',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _authenticatedApp(
            taskRepository: FakeTaskRepository(
              myTasks: [
                buildTestTask(id: 'task-todo', status: TaskStatus.todo),
                buildTestTask(
                  id: 'task-progress',
                  status: TaskStatus.inProgress,
                ),
                buildTestTask(id: 'task-done', status: TaskStatus.completed),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(_badgeCountFor(tester, 'Tasks'), 2);
      },
    );

    testWidgets(
      'badges the dashboard nav item when the viewer\'s profile is incomplete',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _authenticatedApp(
            employeeRepository: FakeEmployeeRepository(
              me: buildTestEmployee(profileCompletionPercentage: 60),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(_badgeCountFor(tester, 'User Dashboard'), 1);
      },
    );

    testWidgets(
      'shows no dashboard badge once the profile is 100% complete',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _authenticatedApp(
            employeeRepository: FakeEmployeeRepository(
              me: buildTestEmployee(profileCompletionPercentage: 100),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(_badgeCountFor(tester, 'User Dashboard'), isNull);
      },
    );
  });
}
