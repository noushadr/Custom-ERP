import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/upcoming_birthday.dart';
import 'package:zera_erp/features/employee/domain/entities/upcoming_work_anniversary.dart';
import 'package:zera_erp/features/employee/presentation/widgets/notification_bell.dart';
import 'package:zera_erp/features/leave/application/leave_providers.dart';
import 'package:zera_erp/features/leave/domain/repositories/leave_repository.dart';
import 'package:zera_erp/features/notices/application/notice_providers.dart';
import 'package:zera_erp/features/notices/domain/entities/notice.dart';
import 'package:zera_erp/features/notifications/application/notifications_providers.dart';
import 'package:zera_erp/features/performance_reviews/application/performance_review_providers.dart';
import 'package:zera_erp/features/requests/application/request_providers.dart';
import 'package:zera_erp/features/requests/domain/entities/employee_request.dart';
import 'package:zera_erp/features/tasks/application/task_providers.dart';
import 'package:zera_erp/features/tasks/domain/entities/task_status.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_leave.dart';
import '../../helpers/fake_notice.dart';
import '../../helpers/fake_notifications.dart';
import '../../helpers/fake_performance_review.dart';
import '../../helpers/fake_request.dart';
import '../../helpers/fake_task.dart';

EmployeeRequest _buildRequest({
  String id = 'request-1',
  String requesterName = 'Ravi Report',
}) {
  return EmployeeRequest(
    id: id,
    requesterId: 'employee-1',
    requesterName: requesterName,
    subject: 'New laptop',
    description: 'My laptop is broken.',
    kind: 'general',
    status: 'submitted',
    createdAt: DateTime(2026, 1, 1),
  );
}

Widget _app({
  required List<String> permissions,
  required FakeEmployeeRepository employeeRepository,
  required FakeRequestRepository requestRepository,
  FakeLeaveRepository? leaveRepository,
  FakeNoticeRepository? noticeRepository,
  FakePerformanceReviewRepository? performanceReviewRepository,
  FakeTaskRepository? taskRepository,
  FakeNotificationsRepository? notificationsRepository,
  String role = 'HR/Manager',
  ValueChanged<NotificationLinkTarget>? onNavigate,
  ValueChanged<String>? onOpenEmployeeProfile,
  ValueChanged<String>? onOpenPerformanceReview,
  ValueChanged<String>? onOpenTask,
  void Function(String? linkTarget, String? linkEntityId)? onOpenNotification,
}) {
  final user = AuthUser(
    id: 'user-1',
    email: 'jane.doe@zeracreative.com',
    role: role,
    permissions: permissions,
  );

  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(user)),
      ),
      employeeRepositoryProvider.overrideWithValue(employeeRepository),
      requestRepositoryProvider.overrideWithValue(requestRepository),
      leaveRepositoryProvider.overrideWithValue(
        leaveRepository ?? FakeLeaveRepository(),
      ),
      noticeRepositoryProvider.overrideWithValue(
        noticeRepository ?? FakeNoticeRepository(),
      ),
      performanceReviewRepositoryProvider.overrideWithValue(
        performanceReviewRepository ?? FakePerformanceReviewRepository(),
      ),
      taskRepositoryProvider.overrideWithValue(
        taskRepository ?? FakeTaskRepository(),
      ),
      notificationsRepositoryProvider.overrideWithValue(
        notificationsRepository ?? FakeNotificationsRepository(),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: NotificationBell(
          onNavigate: onNavigate ?? (_) {},
          onOpenEmployeeProfile: onOpenEmployeeProfile ?? (_) {},
          onOpenPerformanceReview: onOpenPerformanceReview ?? (_) {},
          onOpenTask: onOpenTask ?? (_) {},
          onOpenNotification: onOpenNotification ?? (_, _) {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows a combined badge count and opens birthdays + approvals', (
    tester,
  ) async {
    final employeeRepository = FakeEmployeeRepository(
      upcomingBirthdays: const [
        UpcomingBirthday(
          employeeId: 'employee-2',
          fullName: 'Amna Irfan',
          dateOfBirth: '1997-08-13',
          daysUntil: 1,
        ),
      ],
    );
    final requestRepository = FakeRequestRepository(
      pendingHrApproval: [_buildRequest(id: 'request-hr')],
      pendingManagerApproval: [_buildRequest(id: 'request-manager')],
    );

    await tester.pumpWidget(
      _app(
        permissions: ['employees.manage', 'users.manage'],
        employeeRepository: employeeRepository,
        requestRepository: requestRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('+3'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.textContaining("Amna Irfan's birthday"), findsOneWidget);
    expect(find.text('Awaiting HR approval'), findsOneWidget);
    expect(find.text('Awaiting your approval'), findsOneWidget);
  });

  testWidgets('tapping an HR-approval item navigates to the admin dashboard', (
    tester,
  ) async {
    NotificationLinkTarget? tapped;
    final requestRepository = FakeRequestRepository(
      pendingHrApproval: [_buildRequest(id: 'request-hr')],
    );

    await tester.pumpWidget(
      _app(
        permissions: ['users.manage'],
        employeeRepository: FakeEmployeeRepository(),
        requestRepository: requestRepository,
        onNavigate: (target) => tapped = target,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Awaiting HR approval'));
    await tester.pumpAndSettle();

    expect(tapped, NotificationLinkTarget.adminDashboard);
  });

  testWidgets(
    'tapping a manager-approval item navigates to the user dashboard',
    (tester) async {
      NotificationLinkTarget? tapped;
      final requestRepository = FakeRequestRepository(
        pendingManagerApproval: [_buildRequest(id: 'request-manager')],
      );

      await tester.pumpWidget(
        _app(
          permissions: const [],
          employeeRepository: FakeEmployeeRepository(),
          requestRepository: requestRepository,
          onNavigate: (target) => tapped = target,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Awaiting your approval'));
      await tester.pumpAndSettle();

      expect(tapped, NotificationLinkTarget.userDashboard);
    },
  );

  testWidgets(
    'hides birthdays and HR approvals from a viewer without those permissions',
    (tester) async {
      final employeeRepository = FakeEmployeeRepository(
        upcomingBirthdays: const [
          UpcomingBirthday(
            employeeId: 'employee-2',
            fullName: 'Amna Irfan',
            dateOfBirth: '1997-08-13',
            daysUntil: 1,
          ),
        ],
      );
      final requestRepository = FakeRequestRepository(
        pendingHrApproval: [_buildRequest(id: 'request-hr')],
      );

      await tester.pumpWidget(
        _app(
          permissions: const [],
          employeeRepository: employeeRepository,
          requestRepository: requestRepository,
        ),
      );
      await tester.pumpAndSettle();

      // Neither the birthday nor the HR-only request count toward the
      // badge — this viewer has no employees.manage or users.manage.
      expect(find.textContaining('+'), findsNothing);

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(find.text('No notifications right now.'), findsOneWidget);
    },
  );

  testWidgets(
    'shows a leave request awaiting HR approval and navigates to Leave',
    (tester) async {
      NotificationLinkTarget? tapped;
      final leaveRepository = FakeLeaveRepository(
        pendingHrApproval: [
          buildTestLeaveRequest(id: 'leave-1', requesterName: 'Amna Irfan'),
        ],
      );

      await tester.pumpWidget(
        _app(
          permissions: ['leave.manage'],
          employeeRepository: FakeEmployeeRepository(),
          requestRepository: FakeRequestRepository(),
          leaveRepository: leaveRepository,
          onNavigate: (target) => tapped = target,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Leave awaiting HR approval'), findsOneWidget);
      await tester.tap(find.text('Leave awaiting HR approval'));
      await tester.pumpAndSettle();

      expect(tapped, NotificationLinkTarget.leavePage);
    },
  );

  testWidgets('shows the annual reset reminder for a leave.manage holder', (
    tester,
  ) async {
    final leaveRepository = FakeLeaveRepository(
      resetStatus: const LeaveResetStatus(year: 2027, isInitialized: false),
    );

    await tester.pumpWidget(
      _app(
        permissions: ['leave.manage'],
        employeeRepository: FakeEmployeeRepository(),
        requestRepository: FakeRequestRepository(),
        leaveRepository: leaveRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Annual leave balances for 2027'),
      findsOneWidget,
    );
  });

  testWidgets('shows the viewer\'s own recently-decided leave request', (
    tester,
  ) async {
    final leaveRepository = FakeLeaveRepository(
      myRequests: [
        buildTestLeaveRequest(
          id: 'leave-mine',
          status: 'approved',
          hrDecisionAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        permissions: const [],
        employeeRepository: FakeEmployeeRepository(),
        requestRepository: FakeRequestRepository(),
        leaveRepository: leaveRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Your leave was approved'), findsOneWidget);
    expect(find.text('1 day ago'), findsOneWidget);
  });

  testWidgets('fades an already-decided leave request, since it is old news', (
    tester,
  ) async {
    final leaveRepository = FakeLeaveRepository(
      myRequests: [
        buildTestLeaveRequest(
          id: 'leave-mine',
          status: 'approved',
          hrDecisionAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        permissions: const [],
        employeeRepository: FakeEmployeeRepository(),
        requestRepository: FakeRequestRepository(),
        leaveRepository: leaveRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    final opacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.text('Your leave was approved'),
        matching: find.byType(Opacity),
      ),
    );

    expect(opacity.opacity, lessThan(1.0));
  });

  testWidgets('shows the viewer\'s own recently-decided employee request', (
    tester,
  ) async {
    final requestRepository = FakeRequestRepository(
      mine: [
        buildTestRequest(
          id: 'request-mine',
          requesterName: 'Jane Doe',
          status: 'completed',
          hrDecisionAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        permissions: const [],
        employeeRepository: FakeEmployeeRepository(),
        requestRepository: requestRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Your request was completed'), findsOneWidget);
    expect(find.text('5 hours ago'), findsOneWidget);
  });

  testWidgets(
    'keeps showing a leave decision from weeks ago instead of hiding it',
    (tester) async {
      final leaveRepository = FakeLeaveRepository(
        myRequests: [
          buildTestLeaveRequest(
            id: 'leave-old',
            status: 'rejected',
            hrDecisionAt: DateTime.now().subtract(const Duration(days: 30)),
          ),
        ],
      );

      await tester.pumpWidget(
        _app(
          permissions: const [],
          employeeRepository: FakeEmployeeRepository(),
          requestRepository: FakeRequestRepository(),
          leaveRepository: leaveRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Your leave was rejected'), findsOneWidget);
      expect(find.text('30 days ago'), findsOneWidget);
    },
  );

  testWidgets(
    'shows a birthday that already happened this week as "days ago"',
    (tester) async {
      final employeeRepository = FakeEmployeeRepository(
        upcomingBirthdays: const [
          UpcomingBirthday(
            employeeId: 'employee-2',
            fullName: 'Aamna Irfan',
            dateOfBirth: '1997-08-13',
            daysUntil: -1,
          ),
        ],
      );

      await tester.pumpWidget(
        _app(
          permissions: ['employees.manage'],
          employeeRepository: employeeRepository,
          requestRepository: FakeRequestRepository(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(find.text("Aamna Irfan's birthday"), findsOneWidget);
      expect(find.text('Aug 13 · 1 day ago'), findsOneWidget);
    },
  );

  testWidgets('fades an already-happened birthday but not an upcoming one', (
    tester,
  ) async {
    final employeeRepository = FakeEmployeeRepository(
      upcomingBirthdays: const [
        UpcomingBirthday(
          employeeId: 'employee-2',
          fullName: 'Aamna Irfan',
          dateOfBirth: '1997-08-13',
          daysUntil: -1,
        ),
        UpcomingBirthday(
          employeeId: 'employee-3',
          fullName: 'Ravi Report',
          dateOfBirth: '1990-08-20',
          daysUntil: 2,
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        permissions: ['employees.manage'],
        employeeRepository: employeeRepository,
        requestRepository: FakeRequestRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    final pastOpacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.text("Aamna Irfan's birthday"),
        matching: find.byType(Opacity),
      ),
    );
    final upcomingOpacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.text("Ravi Report's birthday"),
        matching: find.byType(Opacity),
      ),
    );

    expect(pastOpacity.opacity, lessThan(1.0));
    expect(upcomingOpacity.opacity, 1.0);
  });

  testWidgets('tapping a birthday opens that employee\'s profile', (
    tester,
  ) async {
    String? openedEmployeeId;
    final employeeRepository = FakeEmployeeRepository(
      upcomingBirthdays: const [
        UpcomingBirthday(
          employeeId: 'employee-2',
          fullName: 'Aamna Irfan',
          dateOfBirth: '1997-08-13',
          daysUntil: 1,
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        permissions: ['employees.manage'],
        employeeRepository: employeeRepository,
        requestRepository: FakeRequestRepository(),
        onOpenEmployeeProfile: (id) => openedEmployeeId = id,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Aamna Irfan's birthday"));
    await tester.pumpAndSettle();

    expect(openedEmployeeId, 'employee-2');
  });

  testWidgets('shows an upcoming work anniversary with years of service', (
    tester,
  ) async {
    final employeeRepository = FakeEmployeeRepository(
      upcomingWorkAnniversaries: const [
        UpcomingWorkAnniversary(
          employeeId: 'employee-2',
          fullName: 'Aamna Irfan',
          joiningDate: '2023-08-13',
          daysUntil: 1,
          yearsOfService: 3,
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        permissions: ['employees.manage'],
        employeeRepository: employeeRepository,
        requestRepository: FakeRequestRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('+1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.text("Aamna Irfan's 3-year anniversary"), findsOneWidget);
    expect(find.text('Aug 13 · Tomorrow'), findsOneWidget);
  });

  testWidgets('tapping a work anniversary opens that employee\'s profile', (
    tester,
  ) async {
    String? openedEmployeeId;
    final employeeRepository = FakeEmployeeRepository(
      upcomingWorkAnniversaries: const [
        UpcomingWorkAnniversary(
          employeeId: 'employee-2',
          fullName: 'Aamna Irfan',
          joiningDate: '2023-08-13',
          daysUntil: 1,
          yearsOfService: 3,
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        permissions: ['employees.manage'],
        employeeRepository: employeeRepository,
        requestRepository: FakeRequestRepository(),
        onOpenEmployeeProfile: (id) => openedEmployeeId = id,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Aamna Irfan's 3-year anniversary"));
    await tester.pumpAndSettle();

    expect(openedEmployeeId, 'employee-2');
  });

  testWidgets(
    'hides work anniversaries from a viewer without employees.manage',
    (tester) async {
      final employeeRepository = FakeEmployeeRepository(
        upcomingWorkAnniversaries: const [
          UpcomingWorkAnniversary(
            employeeId: 'employee-2',
            fullName: 'Aamna Irfan',
            joiningDate: '2023-08-13',
            daysUntil: 1,
            yearsOfService: 3,
          ),
        ],
      );

      await tester.pumpWidget(
        _app(
          permissions: const [],
          employeeRepository: employeeRepository,
          requestRepository: FakeRequestRepository(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('+'), findsNothing);

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(find.text('No notifications right now.'), findsOneWidget);
    },
  );

  testWidgets('shows a recent company notice and navigates on tap', (
    tester,
  ) async {
    NotificationLinkTarget? tapped;
    final noticeRepository = FakeNoticeRepository(
      notices: [
        Notice(
          id: 'notice-1',
          title: 'Office closed for holiday',
          body: 'All employees get the day off. Enjoy!',
          authorName: 'Noushad',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        permissions: const [],
        employeeRepository: FakeEmployeeRepository(),
        requestRepository: FakeRequestRepository(),
        noticeRepository: noticeRepository,
        onNavigate: (target) => tapped = target,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Office closed for holiday'), findsOneWidget);
    // The full message is readable in the bell, not just the title.
    expect(find.text('All employees get the day off. Enjoy!'), findsOneWidget);
    expect(find.text('2 hours ago'), findsOneWidget);

    await tester.tap(find.text('Office closed for holiday'));
    await tester.pumpAndSettle();

    expect(tapped, NotificationLinkTarget.adminDashboard);
  });

  testWidgets('fades all but the newest company notice', (tester) async {
    final noticeRepository = FakeNoticeRepository(
      notices: [
        Notice(
          id: 'notice-1',
          title: 'Newest notice',
          body: 'Fresh announcement.',
          authorName: 'Noushad',
          createdAt: DateTime.now(),
        ),
        Notice(
          id: 'notice-2',
          title: 'Older notice',
          body: 'Older announcement.',
          authorName: 'Noushad',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        permissions: const [],
        employeeRepository: FakeEmployeeRepository(),
        requestRepository: FakeRequestRepository(),
        noticeRepository: noticeRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    final newestOpacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.text('Newest notice'),
        matching: find.byType(Opacity),
      ),
    );
    final olderOpacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.text('Older notice'),
        matching: find.byType(Opacity),
      ),
    );

    expect(newestOpacity.opacity, 1.0);
    expect(olderOpacity.opacity, lessThan(1.0));
  });

  testWidgets(
    'tapping a notice sets the focused-notice id so the dashboard can jump '
    'to it',
    (tester) async {
      final noticeRepository = FakeNoticeRepository(
        notices: [
          Notice(
            id: 'notice-1',
            title: 'Office closed for holiday',
            body: 'All employees get the day off. Enjoy!',
            authorName: 'Noushad',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => PresetAuthController(
              const AuthAuthenticated(
                AuthUser(
                  id: 'user-1',
                  email: 'jane.doe@zeracreative.com',
                  role: 'HR/Manager',
                  permissions: [],
                ),
              ),
            ),
          ),
          employeeRepositoryProvider.overrideWithValue(
            FakeEmployeeRepository(),
          ),
          requestRepositoryProvider.overrideWithValue(FakeRequestRepository()),
          leaveRepositoryProvider.overrideWithValue(FakeLeaveRepository()),
          noticeRepositoryProvider.overrideWithValue(noticeRepository),
          performanceReviewRepositoryProvider.overrideWithValue(
            FakePerformanceReviewRepository(),
          ),
          taskRepositoryProvider.overrideWithValue(FakeTaskRepository()),
          notificationsRepositoryProvider.overrideWithValue(
            FakeNotificationsRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: NotificationBell(
                onNavigate: (_) {},
                onOpenEmployeeProfile: (_) {},
                onOpenPerformanceReview: (_) {},
                onOpenTask: (_) {},
                onOpenNotification: (_, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(focusedNoticeIdProvider), isNull);

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Office closed for holiday'));
      await tester.pumpAndSettle();

      expect(container.read(focusedNoticeIdProvider), 'notice-1');
    },
  );

  testWidgets(
    'routes a notice tap to the user dashboard for a plain employee',
    (tester) async {
      NotificationLinkTarget? tapped;
      final noticeRepository = FakeNoticeRepository(
        notices: [
          Notice(
            id: 'notice-1',
            title: 'Office closed for holiday',
            body: 'All employees get the day off. Enjoy!',
            authorName: 'Noushad',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ],
      );

      await tester.pumpWidget(
        _app(
          permissions: const [],
          role: 'Employee',
          employeeRepository: FakeEmployeeRepository(),
          requestRepository: FakeRequestRepository(),
          noticeRepository: noticeRepository,
          onNavigate: (target) => tapped = target,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Office closed for holiday'));
      await tester.pumpAndSettle();

      expect(tapped, NotificationLinkTarget.userDashboard);
    },
  );

  testWidgets(
    'shows a newly-assigned task and opens it on tap',
    (tester) async {
      String? openedTaskId;
      final taskRepository = FakeTaskRepository(
        myTasks: [
          buildTestTask(
            id: 'task-1',
            title: 'Write report',
            assignedByName: 'Manager Person',
            status: TaskStatus.todo,
          ),
        ],
      );

      await tester.pumpWidget(
        _app(
          permissions: const [],
          employeeRepository: FakeEmployeeRepository(),
          requestRepository: FakeRequestRepository(),
          taskRepository: taskRepository,
          onOpenTask: (id) => openedTaskId = id,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Write report'), findsOneWidget);
      expect(find.text('Assigned by Manager Person'), findsOneWidget);

      await tester.tap(find.text('Write report'));
      await tester.pumpAndSettle();

      expect(openedTaskId, 'task-1');
    },
  );

  testWidgets(
    'does not show an in-progress task under newly-assigned',
    (tester) async {
      final taskRepository = FakeTaskRepository(
        myTasks: [
          buildTestTask(
            id: 'task-1',
            title: 'Already started',
            status: TaskStatus.inProgress,
            dueDate: '2099-01-01',
          ),
        ],
      );

      await tester.pumpWidget(
        _app(
          permissions: const [],
          employeeRepository: FakeEmployeeRepository(),
          requestRepository: FakeRequestRepository(),
          taskRepository: taskRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Already started'), findsNothing);
    },
  );

  testWidgets('shows a task that is due soon, but not a completed one', (
    tester,
  ) async {
    final soonDueDate =
        DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(
          0,
          10,
        );
    final taskRepository = FakeTaskRepository(
      myTasks: [
        buildTestTask(
          id: 'task-1',
          title: 'Due soon task',
          status: TaskStatus.inProgress,
          dueDate: soonDueDate,
        ),
        buildTestTask(
          id: 'task-2',
          title: 'Completed task',
          status: TaskStatus.completed,
          dueDate: soonDueDate,
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        permissions: const [],
        employeeRepository: FakeEmployeeRepository(),
        requestRepository: FakeRequestRepository(),
        taskRepository: taskRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.textContaining('Due soon task'), findsOneWidget);
    expect(find.textContaining('Completed task'), findsNothing);
  });
}
