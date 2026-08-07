import '../entities/employee_request.dart';

abstract interface class RequestRepository {
  /// Throws [RequestException] on failure.
  Future<EmployeeRequest> submit({
    required String subject,
    required String description,
    String? type,
  });

  Future<List<EmployeeRequest>> getMine();

  /// Requests submitted by one of this viewer's direct reports, awaiting
  /// their approval.
  Future<List<EmployeeRequest>> getPendingManagerApproval();

  /// Requires `users.manage`.
  Future<List<EmployeeRequest>> getPendingHrApproval();

  Future<EmployeeRequest> approveAsManager(String requestId);

  Future<EmployeeRequest> rejectAsManager(String requestId, {String? reason});

  /// Requires `users.manage`.
  Future<EmployeeRequest> approveAsHr(String requestId);

  /// Requires `users.manage`.
  Future<EmployeeRequest> rejectAsHr(String requestId, {String? reason});
}
