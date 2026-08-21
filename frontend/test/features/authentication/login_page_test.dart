import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/authentication/domain/exceptions/auth_exception.dart';
import 'package:zera_erp/features/authentication/presentation/pages/login_page.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/knowledge_base/application/knowledge_base_providers.dart';
import 'package:zera_erp/features/leave/application/leave_providers.dart';
import 'package:zera_erp/features/notices/application/notice_providers.dart';
import 'package:zera_erp/features/performance_reviews/application/performance_review_providers.dart';
import 'package:zera_erp/features/requests/application/request_providers.dart';
import 'package:zera_erp/features/tasks/application/task_providers.dart';
import 'package:zera_erp/main.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_knowledge_base.dart';
import '../../helpers/fake_leave.dart';
import '../../helpers/fake_notice.dart';
import '../../helpers/fake_performance_review.dart';
import '../../helpers/fake_request.dart';
import '../../helpers/fake_task.dart';

class _DelayedAuthRepository extends FakeAuthRepository {
  _DelayedAuthRepository(this.completer);

  final Completer<AuthUser> completer;

  @override
  Future<AuthUser> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) => completer.future;
}

Widget _appWith(FakeAuthRepository repository) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
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
    ],
    child: const ZeraApp(),
  );
}

Future<void> _enterCredentials(
  WidgetTester tester, {
  String email = 'jane.doe@zeracreative.com',
  String password = 'super-secret',
}) async {
  await tester.enterText(find.byKey(const Key('loginEmailField')), email);
  await tester.enterText(find.byKey(const Key('loginPasswordField')), password);
}

void main() {
  testWidgets('shows validation errors for empty fields', (tester) async {
    await tester.pumpWidget(_appWith(FakeAuthRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('loginEmailField')), '');
    await tester.enterText(find.byKey(const Key('loginPasswordField')), '');
    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('shows a validation error for a malformed email', (
    tester,
  ) async {
    await tester.pumpWidget(_appWith(FakeAuthRepository()));
    await tester.pumpAndSettle();

    await _enterCredentials(tester, email: 'not-an-email');
    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('shows a loading indicator while signing in', (tester) async {
    final completer = Completer<AuthUser>();
    await tester.pumpWidget(_appWith(_DelayedAuthRepository(completer)));
    await tester.pumpAndSettle();

    await _enterCredentials(tester);
    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(testAuthUser);
    await tester.pumpAndSettle();
  });

  testWidgets('shows an error banner when login fails', (tester) async {
    await tester.pumpWidget(
      _appWith(
        FakeAuthRepository(
          loginError: const AuthException('Invalid email or password.'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _enterCredentials(tester);
    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password.'), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('navigates to the authenticated shell on success', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWith(FakeAuthRepository(loginResult: testAuthUser)),
    );
    await tester.pumpAndSettle();

    await _enterCredentials(tester);
    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsNothing);
    expect(find.text('Company Notices'), findsOneWidget);
  });

  testWidgets('remembers the session by default', (tester) async {
    final repository = FakeAuthRepository(loginResult: testAuthUser);
    await tester.pumpWidget(_appWith(repository));
    await tester.pumpAndSettle();

    await _enterCredentials(tester);
    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pumpAndSettle();

    expect(repository.lastRememberMe, isTrue);
  });

  testWidgets('unchecking "Remember me" logs in without persisting', (
    tester,
  ) async {
    final repository = FakeAuthRepository(loginResult: testAuthUser);
    await tester.pumpWidget(_appWith(repository));
    await tester.pumpAndSettle();

    await _enterCredentials(tester);
    await tester.tap(find.byKey(const Key('rememberMeCheckbox')));
    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pumpAndSettle();

    expect(repository.lastRememberMe, isFalse);
    expect(find.byType(LoginPage), findsNothing);
  });
}
