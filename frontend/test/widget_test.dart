import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/announcements/application/announcement_providers.dart';
import 'package:zera_erp/features/announcements/domain/entities/today_announcements.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/checklists/application/checklist_providers.dart';
import 'package:zera_erp/features/clients/application/clients_providers.dart';
import 'package:zera_erp/features/email/application/email_providers.dart';
import 'package:zera_erp/shared/utils/date_format.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/birthday_spotlight.dart';
import 'package:zera_erp/features/employee/domain/entities/employee.dart';
import 'package:zera_erp/features/employee/domain/entities/payroll_summary.dart';
import 'package:zera_erp/features/employee/domain/entities/upcoming_birthday.dart';
import 'package:zera_erp/features/employee/domain/entities/upcoming_work_anniversary.dart';
import 'package:zera_erp/features/freelancers/application/freelancers_providers.dart';
import 'package:zera_erp/features/goals/application/goal_providers.dart';
import 'package:zera_erp/features/holidays/application/holiday_providers.dart';
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

import 'package:zera_erp/main.dart';
import 'helpers/fake_announcements.dart';
import 'helpers/fake_auth.dart';
import 'helpers/fake_checklist.dart';
import 'helpers/fake_clients.dart';
import 'helpers/fake_email.dart';
import 'helpers/fake_employee.dart';
import 'helpers/fake_freelancers.dart';
import 'helpers/fake_goal.dart';
import 'helpers/fake_holiday.dart';
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
  FakeFreelancersRepository? freelancersRepository,
  FakeGoalRepository? goalRepository,
  FakeEmailRepository? emailRepository,
  FakePayrollRepository? payrollRepository,
  FakeAnnouncementsRepository? announcementsRepository,
  FakeHolidayRepository? holidayRepository,
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
      announcementsRepositoryProvider.overrideWithValue(
        announcementsRepository ?? FakeAnnouncementsRepository(),
      ),
      holidayRepositoryProvider.overrideWithValue(
        holidayRepository ?? FakeHolidayRepository(),
      ),
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
      checklistRepositoryProvider.overrideWithValue(FakeChecklistRepository()),
      notificationsRepositoryProvider.overrideWithValue(
        FakeNotificationsRepository(),
      ),
      payrollRepositoryProvider.overrideWithValue(
        payrollRepository ?? FakePayrollRepository(),
      ),
      freelancersRepositoryProvider.overrideWithValue(
        freelancersRepository ?? FakeFreelancersRepository(),
      ),
      leadsRepositoryProvider.overrideWithValue(FakeLeadsRepository()),
      goalRepositoryProvider.overrideWithValue(
        goalRepository ?? FakeGoalRepository(),
      ),
      emailRepositoryProvider.overrideWithValue(
        emailRepository ?? FakeEmailRepository(),
      ),
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
    // No direct reports in the fake by default — the whole My Team card is
    // hidden rather than showing an empty "(0)" one.
    expect(find.text('My Team'), findsNothing);
    expect(find.textContaining('My Team ('), findsNothing);
    expect(find.text('My Goals'), findsOneWidget);
    expect(find.text('No goals have been set for you yet.'), findsOneWidget);
    expect(find.text('My Tasks'), findsOneWidget);
    expect(find.text('No tasks yet.'), findsOneWidget);
  });

  testWidgets(
    'shows My Team when the employee has direct reports, hides it when '
    'they have none',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _authenticatedApp(
          employeeRepository: FakeEmployeeRepository(
            employees: [buildTestEmployee()],
            directReports: [
              buildTestEmployee(id: 'report-1', fullName: 'Report One'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Team (1)'), findsOneWidget);
      expect(find.text('Report One'), findsOneWidget);
    },
  );

  testWidgets('shows tasks assigned to the employee and tasks they assigned to '
      'others, in separate groups', (WidgetTester tester) async {
    await tester.pumpWidget(
      _authenticatedApp(
        taskRepository: FakeTaskRepository(
          myTasks: [buildTestTask(id: 'task-1', title: 'Write the report')],
          tasksAssignedByMe: [
            buildTestTask(id: 'task-2', title: 'Review the design'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Assigned to you'), findsOneWidget);
    expect(find.text('Write the report'), findsOneWidget);
    expect(find.text('Assigned by you'), findsOneWidget);
    expect(find.text('Review the design'), findsOneWidget);
  });

  testWidgets('shows a goal set for the employee on their dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _authenticatedApp(
        goalRepository: FakeGoalRepository(
          mine: [
            buildTestGoal(
              title: 'English speaking',
              description: 'Practice daily with the team',
              createdByName: 'Muhammad Bilal Rathore',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('English speaking'), findsOneWidget);
    expect(find.text('Practice daily with the team'), findsOneWidget);
    expect(find.text('Set by Muhammad Bilal Rathore'), findsOneWidget);
  });

  testWidgets('admin dashboard shows the current Employee of the Month', (
    WidgetTester tester,
  ) async {
    const admin = AuthUser(
      id: 'admin-1',
      email: 'admin@zeracreative.com',
      role: 'Super Admin',
      permissions: [],
    );

    await tester.pumpWidget(
      _authenticatedApp(
        user: admin,
        announcementsRepository: FakeAnnouncementsRepository(
          today: const TodayAnnouncements(
            birthdays: [],
            workAnniversaries: [],
            holiday: null,
            notices: [],
            employeeOfTheMonth: TodayEmployeeOfMonth(
              employeeId: 'employee-1',
              fullName: 'Muhammad Asad Rathore',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Employee of the Month'), findsOneWidget);
    expect(find.text('Muhammad Asad Rathore'), findsOneWidget);
  });

  testWidgets(
    "tapping the Employee of the Month spotlight opens that employee's own "
    'profile',
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
          announcementsRepository: FakeAnnouncementsRepository(
            today: const TodayAnnouncements(
              birthdays: [],
              workAnniversaries: [],
              holiday: null,
              notices: [],
              employeeOfTheMonth: TodayEmployeeOfMonth(
                employeeId: 'employee-1',
                fullName: 'Muhammad Asad Rathore',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Muhammad Asad Rathore'));
      await tester.pumpAndSettle();

      expect(find.text('Employee Profile'), findsOneWidget);
    },
  );

  testWidgets("admin dashboard's top bar shows today's date", (
    WidgetTester tester,
  ) async {
    // The date only shows on the desktop-width top bar (`_TopBar`) — the
    // default test surface falls in the tablet range, which uses a plain
    // AppBar instead.
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const admin = AuthUser(
      id: 'admin-1',
      email: 'admin@zeracreative.com',
      role: 'Super Admin',
      permissions: [],
    );

    await tester.pumpWidget(_authenticatedApp(user: admin));
    await tester.pumpAndSettle();

    expect(find.text(formatDisplayDateOnly(DateTime.now())), findsOneWidget);
  });

  testWidgets(
    "admin dashboard's Post notice button lives on the Company Notices card, "
    'not floating above it',
    (WidgetTester tester) async {
      const admin = AuthUser(
        id: 'admin-1',
        email: 'admin@zeracreative.com',
        role: 'Super Admin',
        permissions: [],
      );

      await tester.pumpWidget(_authenticatedApp(user: admin));
      await tester.pumpAndSettle();

      final noticesCard = find.ancestor(
        of: find.text('Company Notices'),
        matching: find.byType(Card),
      );
      expect(noticesCard, findsOneWidget);
      expect(
        find.descendant(of: noticesCard, matching: find.text('Post notice')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    "admin dashboard shows 'No Employee of the Month right now.' when none "
    'is currently active',
    (WidgetTester tester) async {
      const admin = AuthUser(
        id: 'admin-1',
        email: 'admin@zeracreative.com',
        role: 'Super Admin',
        permissions: [],
      );

      await tester.pumpWidget(_authenticatedApp(user: admin));
      await tester.pumpAndSettle();

      expect(find.text('No Employee of the Month right now.'), findsOneWidget);
    },
  );

  testWidgets(
    'admin dashboard shows the most recent past birthday and the soonest '
    'upcoming one',
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
          employeeRepository: FakeEmployeeRepository(
            employees: [buildTestEmployee()],
            birthdaySpotlight: const BirthdaySpotlight(
              last: UpcomingBirthday(
                employeeId: 'employee-2',
                fullName: 'Aamna Irfan',
                dateOfBirth: '1997-08-13',
                daysUntil: -2,
              ),
              upcoming: UpcomingBirthday(
                employeeId: 'employee-3',
                fullName: 'Babar Hussain',
                dateOfBirth: '1995-09-20',
                daysUntil: 5,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Last Birthday'), findsOneWidget);
      expect(find.text('Aamna Irfan'), findsOneWidget);
      expect(find.text('Aug 13 · 2 days ago'), findsOneWidget);
      expect(find.text('Upcoming Birthday'), findsOneWidget);
      expect(find.text('Babar Hussain'), findsOneWidget);
      expect(find.text('Sep 20 · in 5 days'), findsOneWidget);
    },
  );

  testWidgets(
    'admin dashboard shows every work anniversary in the spotlight month',
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
          employeeRepository: FakeEmployeeRepository(
            employees: [buildTestEmployee()],
            workAnniversarySpotlight: const [
              UpcomingWorkAnniversary(
                employeeId: 'employee-2',
                fullName: 'Aamna Irfan',
                joiningDate: '2023-09-25',
                daysUntil: 7,
                yearsOfService: 3,
              ),
              UpcomingWorkAnniversary(
                employeeId: 'employee-3',
                fullName: 'Babar Hussain',
                joiningDate: '2020-09-30',
                daysUntil: 12,
                yearsOfService: 6,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upcoming Work Anniversary'), findsOneWidget);
      expect(find.text('Aamna Irfan'), findsOneWidget);
      expect(find.text('3 years · in 7 days'), findsOneWidget);
      expect(find.text('Babar Hussain'), findsOneWidget);
      expect(find.text('6 years · in 12 days'), findsOneWidget);
    },
  );

  testWidgets('admin dashboard shows the soonest upcoming public holiday', (
    WidgetTester tester,
  ) async {
    const admin = AuthUser(
      id: 'admin-1',
      email: 'admin@zeracreative.com',
      role: 'Super Admin',
      permissions: [],
    );
    final soon = DateTime.now().add(const Duration(days: 10));
    final soonIso =
        '${soon.year.toString().padLeft(4, '0')}-'
        '${soon.month.toString().padLeft(2, '0')}-'
        '${soon.day.toString().padLeft(2, '0')}';
    final past = DateTime.now().subtract(const Duration(days: 10));
    final pastIso =
        '${past.year.toString().padLeft(4, '0')}-'
        '${past.month.toString().padLeft(2, '0')}-'
        '${past.day.toString().padLeft(2, '0')}';

    await tester.pumpWidget(
      _authenticatedApp(
        user: admin,
        holidayRepository: FakeHolidayRepository(
          holidays: [
            buildTestHoliday(
              id: 'holiday-past',
              name: 'Already Happened',
              date: pastIso,
            ),
            buildTestHoliday(
              id: 'holiday-soon',
              name: 'Independence Day',
              date: soonIso,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upcoming Public Holiday'), findsOneWidget);
    expect(find.text('Independence Day'), findsOneWidget);
    expect(find.text('Already Happened'), findsNothing);
  });

  testWidgets(
    'admin dashboard shows a company-wide Tasks summary: total, pending/in '
    'progress, and done',
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
          taskRepository: FakeTaskRepository(
            teamTasks: [
              buildTestTask(id: 'task-1', status: TaskStatus.todo),
              buildTestTask(id: 'task-2', status: TaskStatus.inProgress),
              buildTestTask(id: 'task-3', status: TaskStatus.pending),
              buildTestTask(id: 'task-4', status: TaskStatus.completed),
              buildTestTask(id: 'task-5', status: TaskStatus.completed),
              buildTestTask(id: 'task-6', status: TaskStatus.cancelled),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "Tasks" also appears as a nav label — the summary card's own labels
      // below are unambiguous instead.
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('Pending / In Progress'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping the Tasks spotlight card switches to the Tasks section',
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
          taskRepository: FakeTaskRepository(
            teamTasks: [buildTestTask(id: 'task-1', status: TaskStatus.todo)],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scoped to the spotlight card's own InkWell (identified by its icon) —
      // 'Tasks' is also the nav item's own label, which would trivially pass
      // this test on its own without ever exercising the card's tap handler.
      await tester.tap(
        find.ancestor(
          of: find.byIcon(Icons.checklist_outlined),
          matching: find.byType(InkWell),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Tasks'), findsOneWidget);
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

  testWidgets('shows Employees and Settings in the nav for a Super Admin', (
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

    expect(find.text('Employees'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('shows Clients & Projects in the nav for a Super Admin', (
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

    expect(find.text('Clients & Projects'), findsOneWidget);
  });

  testWidgets('shows Clients & Projects in the nav for HR/Manager too', (
    WidgetTester tester,
  ) async {
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
  });

  testWidgets('hides Clients & Projects from the nav for a plain employee', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_authenticatedApp());
    await tester.pumpAndSettle();

    expect(find.text('Clients & Projects'), findsNothing);
  });

  testWidgets('shows Payroll in the nav for a Super Admin', (
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

    expect(find.text('Payroll'), findsOneWidget);
  });

  testWidgets('shows Payroll in the nav for HR/Manager too', (
    WidgetTester tester,
  ) async {
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
  });

  testWidgets('hides Payroll from the nav for a plain employee', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_authenticatedApp());
    await tester.pumpAndSettle();

    expect(find.text('Payroll'), findsNothing);
  });

  testWidgets('shows Logs in the nav for a Super Admin', (
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

    expect(find.text('Logs'), findsOneWidget);
  });

  testWidgets('shows Logs in the nav for HR/Manager too', (
    WidgetTester tester,
  ) async {
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

    // HR/Manager shares Logs with Super Admin, same as Clients & Projects
    // and Payroll.
    expect(find.text('Employees'), findsOneWidget);
    expect(find.text('Logs'), findsOneWidget);
  });

  testWidgets('shows Logs in the nav for a plain employee too, unlike other '
      'admin-only destinations', (WidgetTester tester) async {
    await tester.pumpWidget(_authenticatedApp());
    await tester.pumpAndSettle();

    // Everyone gets a Logs destination now (their own change history for
    // non-audit.viewAll holders — see LogsPage) — only the company-wide
    // admin modules stay hidden from a plain employee.
    expect(find.text('Logs'), findsOneWidget);
    expect(find.text('Payroll'), findsNothing);
  });

  testWidgets(
    'shows Goals in the nav for every role, including a plain employee',
    (WidgetTester tester) async {
      await tester.pumpWidget(_authenticatedApp());
      await tester.pumpAndSettle();

      expect(find.text('Goals'), findsOneWidget);
    },
  );

  testWidgets(
    'shows Email in the nav for every role, including a plain employee',
    (WidgetTester tester) async {
      await tester.pumpWidget(_authenticatedApp());
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
    },
  );

  testWidgets('a Super Admin sees only Dashboard, never User Dashboard', (
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

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('User Dashboard'), findsNothing);
    expect(find.text('Employee of the Month'), findsOneWidget);
  });

  testWidgets('a plain employee sees only User Dashboard, never Dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_authenticatedApp());
    await tester.pumpAndSettle();

    expect(find.text('User Dashboard'), findsWidgets);
    expect(find.text('Dashboard'), findsNothing);
    expect(find.text('Employee of the Month'), findsNothing);
  });

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

    testWidgets('shows no dashboard badge once the profile is 100% complete', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _authenticatedApp(
          employeeRepository: FakeEmployeeRepository(
            me: buildTestEmployee(profileCompletionPercentage: 100),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_badgeCountFor(tester, 'User Dashboard'), isNull);
    });
  });
}
