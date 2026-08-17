import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/core/theme/app_colors.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/exceptions/employee_exception.dart';
import 'package:zera_erp/features/employee/presentation/pages/user_dashboard_page.dart';
import 'package:zera_erp/features/leave/application/leave_providers.dart';
import 'package:zera_erp/features/notices/application/notice_providers.dart';
import 'package:zera_erp/features/notices/domain/entities/notice.dart';
import 'package:zera_erp/shared/models/named_ref.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_leave.dart';
import '../../helpers/fake_notice.dart';

Future<void> _useTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

const _viewer = AuthUser(
  id: 'user-1',
  email: 'jane.doe@zeracreative.com',
  role: 'Employee',
  permissions: [],
);

Widget _app({
  AuthUser viewer = _viewer,
  FakeEmployeeRepository? employeeRepository,
  FakeNoticeRepository? noticeRepository,
  FakeAuthRepository? authRepository,
  FakeLeaveRepository? leaveRepository,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(
          AuthAuthenticated(viewer),
          repository: authRepository,
        ),
      ),
      employeeRepositoryProvider.overrideWithValue(
        employeeRepository ?? FakeEmployeeRepository(),
      ),
      noticeRepositoryProvider.overrideWithValue(
        noticeRepository ?? FakeNoticeRepository(),
      ),
      leaveRepositoryProvider.overrideWithValue(
        leaveRepository ?? FakeLeaveRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: UserDashboardPage())),
  );
}

void main() {
  testWidgets(
    'shows a friendly message when the viewer has no employee profile',
    (tester) async {
      await tester.pumpWidget(
        _app(
          employeeRepository: FakeEmployeeRepository(
            getMeError: const EmployeeException('Not found.'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining("isn't linked to an employee profile"),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows company notices from the feed', (tester) async {
    await tester.pumpWidget(
      _app(
        noticeRepository: FakeNoticeRepository(
          notices: [
            Notice(
              id: 'notice-1',
              title: 'Office closed',
              body: 'Closed for the holiday.',
              authorName: 'HR Team',
              createdAt: DateTime(2026, 1, 1),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Office closed'), findsOneWidget);
    expect(find.text('Closed for the holiday.'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no notices', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('No company notices yet.'), findsOneWidget);
  });

  testWidgets(
    'paginates notices 3 per page, revealing older ones via page 2',
    (tester) async {
      await _useTallSurface(tester);
      final notices = [
        for (var i = 4; i >= 1; i--)
          Notice(
            id: 'notice-$i',
            title: 'Notice $i',
            body: 'Body $i',
            authorName: 'HR Team',
            createdAt: DateTime(2026, i),
          ),
      ];
      await tester.pumpWidget(
        _app(noticeRepository: FakeNoticeRepository(notices: notices)),
      );
      await tester.pumpAndSettle();

      // Newest 3 shown on page 1; the oldest is on page 2.
      expect(find.text('Notice 4'), findsOneWidget);
      expect(find.text('Notice 3'), findsOneWidget);
      expect(find.text('Notice 2'), findsOneWidget);
      expect(find.text('Notice 1'), findsNothing);

      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      expect(find.text('Notice 1'), findsOneWidget);
      expect(find.text('Notice 4'), findsNothing);
    },
  );

  testWidgets(
    'hides the delete button from a viewer without notices.manage',
    (tester) async {
      await tester.pumpWidget(
        _app(
          noticeRepository: FakeNoticeRepository(
            notices: [
              Notice(
                id: 'notice-1',
                title: 'Office closed',
                body: 'Closed for the holiday.',
                authorName: 'HR Team',
                createdAt: DateTime(2026, 1, 1),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Delete notice'), findsNothing);
    },
  );

  testWidgets(
    'HR/Admin can delete a notice after confirming',
    (tester) async {
      final noticeRepository = FakeNoticeRepository(
        notices: [
          Notice(
            id: 'notice-1',
            title: 'Office closed',
            body: 'Closed for the holiday.',
            authorName: 'HR Team',
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      );
      await tester.pumpWidget(
        _app(
          viewer: const AuthUser(
            id: 'user-1',
            email: 'jane.doe@zeracreative.com',
            role: 'HR/Manager',
            permissions: ['notices.manage'],
          ),
          noticeRepository: noticeRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete notice'));
      await tester.pumpAndSettle();

      expect(find.text('Delete notice?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(noticeRepository.lastDeletedId, 'notice-1');
    },
  );

  testWidgets(
    'hides the edit button from a viewer without notices.manage',
    (tester) async {
      await tester.pumpWidget(
        _app(
          noticeRepository: FakeNoticeRepository(
            notices: [
              Notice(
                id: 'notice-1',
                title: 'Office closed',
                body: 'Closed for the holiday.',
                authorName: 'HR Team',
                createdAt: DateTime(2026, 1, 1),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Edit notice'), findsNothing);
    },
  );

  testWidgets(
    'HR/Admin can edit a notice, pre-filled with its current text',
    (tester) async {
      final noticeRepository = FakeNoticeRepository(
        notices: [
          Notice(
            id: 'notice-1',
            title: 'Office closed',
            body: 'Closed for the holiday.',
            authorName: 'HR Team',
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      );
      await tester.pumpWidget(
        _app(
          viewer: const AuthUser(
            id: 'user-1',
            email: 'jane.doe@zeracreative.com',
            role: 'HR/Manager',
            permissions: ['notices.manage'],
          ),
          noticeRepository: noticeRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Edit notice'));
      await tester.pumpAndSettle();

      expect(find.text('Edit notice'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Office closed'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Closed for the holiday.'),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Office closed early',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(noticeRepository.lastUpdatedId, 'notice-1');
      expect(noticeRepository.lastUpdatedTitle, 'Office closed early');
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets('only highlights the newest notice; older ones are muted', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        noticeRepository: FakeNoticeRepository(
          notices: [
            Notice(
              id: 'notice-2',
              title: 'Newest notice',
              body: 'Body 2',
              authorName: 'HR Team',
              createdAt: DateTime(2026, 2, 1),
            ),
            Notice(
              id: 'notice-1',
              title: 'Older notice',
              body: 'Body 1',
              authorName: 'HR Team',
              createdAt: DateTime(2026, 1, 1),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final newestCard = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Newest notice'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((newestCard.decoration as BoxDecoration).color, AppColors.primarySoft);

    final olderCard = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Older notice'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((olderCard.decoration as BoxDecoration).color, AppColors.fieldFill);
  });

  testWidgets('shows the same leave balances as the leave page', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        leaveRepository: FakeLeaveRepository(
          myBalances: [
            buildTestLeaveBalance(
              leaveTypeName: 'Annual Leave',
              allocated: 20,
              used: 4,
              remaining: 16,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Leave Balances'), findsOneWidget);
    expect(find.text('Annual Leave'), findsOneWidget);
    expect(find.text('16'), findsOneWidget);
    expect(find.text('remaining of 20'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no leave balances', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('No leave balances yet.'), findsOneWidget);
  });

  testWidgets('changing password calls the auth controller', (tester) async {
    final authRepository = FakeAuthRepository();
    await tester.pumpWidget(_app(authRepository: authRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Current password'),
      'old-password',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New password'),
      'new-password-123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm new password'),
      'new-password-123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Change password'));
    await tester.pumpAndSettle();

    expect(authRepository.lastChangePasswordNewPassword, 'new-password-123');
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('shows a validation error when the new passwords do not match', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository();
    await tester.pumpWidget(_app(authRepository: authRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Current password'),
      'old-password',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New password'),
      'new-password-123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm new password'),
      'does-not-match',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Change password'));
    await tester.pumpAndSettle();

    expect(find.text("Passwords don't match"), findsOneWidget);
    expect(authRepository.lastChangePasswordNewPassword, isNull);
  });

  testWidgets('shows team members assigned to the viewer', (tester) async {
    await tester.pumpWidget(
      _app(
        employeeRepository: FakeEmployeeRepository(
          directReports: [buildTestEmployee(fullName: 'Ravi Report')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ravi Report'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no team members', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(
      find.text('No team members are assigned to you yet.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows employment status, work mode, department, and reporting manager',
    (tester) async {
      await tester.pumpWidget(
        _app(
          employeeRepository: FakeEmployeeRepository(
            me: buildTestEmployee(
              employmentStatus: 'notice_period',
              workMode: 'remote',
              department: const NamedRef(id: 'dept-1', name: 'Engineering'),
              reportingManager: const NamedRef(
                id: 'mgr-1',
                name: 'Jane Manager',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notice Period'), findsOneWidget);
      expect(find.text('Remote'), findsOneWidget);
      expect(find.text('Department: Engineering'), findsOneWidget);
      expect(find.text('Reporting Manager: Jane Manager'), findsOneWidget);
    },
  );
}
