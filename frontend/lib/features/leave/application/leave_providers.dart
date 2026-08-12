import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/leave_remote_data_source.dart';
import '../data/repositories/leave_repository_impl.dart';
import '../domain/entities/leave_balance.dart';
import '../domain/entities/leave_calendar_entry.dart';
import '../domain/entities/leave_request.dart';
import '../domain/entities/leave_type.dart';
import '../domain/repositories/leave_repository.dart';

final leaveRemoteDataSourceProvider = Provider<LeaveRemoteDataSource>(
  (ref) => LeaveRemoteDataSource(ref.watch(dioClientProvider).dio),
);

final leaveRepositoryProvider = Provider<LeaveRepository>(
  (ref) => LeaveRepositoryImpl(ref.watch(leaveRemoteDataSourceProvider)),
);

// Every provider below re-watches authControllerProvider purely to create a
// dependency edge, so switching identity (impersonate/returnToAdmin/logout)
// triggers a refetch — see the longer explanation in employee_providers.dart.

final leaveTypesProvider = FutureProvider.autoDispose
    .family<List<LeaveType>, bool>((ref, includeArchived) {
      ref.watch(authControllerProvider);
      return ref
          .watch(leaveRepositoryProvider)
          .getLeaveTypes(includeArchived: includeArchived);
    });

final myLeaveBalancesProvider = FutureProvider.autoDispose<List<LeaveBalance>>(
  (ref) {
    ref.watch(authControllerProvider);
    return ref.watch(leaveRepositoryProvider).getMyBalances();
  },
);

final myLeaveRequestsProvider = FutureProvider.autoDispose<List<LeaveRequest>>(
  (ref) {
    ref.watch(authControllerProvider);
    return ref.watch(leaveRepositoryProvider).getMyLeaveRequests();
  },
);

final pendingManagerApprovalLeaveRequestsProvider =
    FutureProvider.autoDispose<List<LeaveRequest>>((ref) {
      ref.watch(authControllerProvider);
      return ref.watch(leaveRepositoryProvider).getPendingManagerApproval();
    });

final pendingHrApprovalLeaveRequestsProvider =
    FutureProvider.autoDispose<List<LeaveRequest>>((ref) {
      ref.watch(authControllerProvider);
      return ref.watch(leaveRepositoryProvider).getPendingHrApproval();
    });

/// Gated to `leave.manage` by callers — Employee/Team Lead viewers never
/// watch this, since the reset action isn't available to them anyway.
final leaveResetStatusProvider = FutureProvider.autoDispose<LeaveResetStatus>((
  ref,
) {
  ref.watch(authControllerProvider);
  return ref.watch(leaveRepositoryProvider).getResetStatus();
});

class LeaveCalendarQuery {
  const LeaveCalendarQuery({
    required this.scope,
    required this.month,
    required this.year,
  });

  final String scope;
  final int month;
  final int year;

  @override
  bool operator ==(Object other) =>
      other is LeaveCalendarQuery &&
      other.scope == scope &&
      other.month == month &&
      other.year == year;

  @override
  int get hashCode => Object.hash(scope, month, year);
}

final leaveCalendarProvider = FutureProvider.autoDispose
    .family<List<LeaveCalendarEntry>, LeaveCalendarQuery>((ref, query) {
      ref.watch(authControllerProvider);
      return ref
          .watch(leaveRepositoryProvider)
          .getLeaveCalendar(
            scope: query.scope,
            month: query.month,
            year: query.year,
          );
    });
