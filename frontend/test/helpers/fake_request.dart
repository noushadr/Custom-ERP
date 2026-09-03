import 'package:zera_erp/features/requests/domain/entities/employee_request.dart';
import 'package:zera_erp/features/requests/domain/repositories/request_repository.dart';

EmployeeRequest buildTestRequest({
  String id = 'request-1',
  String requesterId = 'employee-1',
  String requesterName = 'Jane Doe',
  String subject = 'New laptop',
  String description = 'Current one is broken.',
  String kind = 'general',
  String status = 'submitted',
  DateTime? managerDecisionAt,
  String? managerDecisionByName,
  DateTime? hrDecisionAt,
  String? hrDecisionByName,
  String? rejectionReason,
  DateTime? createdAt,
}) {
  return EmployeeRequest(
    id: id,
    requesterId: requesterId,
    requesterName: requesterName,
    subject: subject,
    description: description,
    kind: kind,
    status: status,
    managerDecisionAt: managerDecisionAt,
    managerDecisionByName: managerDecisionByName,
    hrDecisionAt: hrDecisionAt,
    hrDecisionByName: hrDecisionByName,
    rejectionReason: rejectionReason,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}

class FakeRequestRepository implements RequestRepository {
  FakeRequestRepository({
    this.mine = const [],
    this.pendingManagerApproval = const [],
    this.pendingHrApproval = const [],
    this.history = const [],
    this.historyForMyTeam = const [],
    this.submitError,
    this.decisionError,
  });

  final List<EmployeeRequest> mine;
  final List<EmployeeRequest> pendingManagerApproval;
  final List<EmployeeRequest> pendingHrApproval;
  final List<EmployeeRequest> history;
  final List<EmployeeRequest> historyForMyTeam;
  final Object? submitError;
  final Object? decisionError;

  String? lastSubmittedSubject;
  Map<String, dynamic>? lastProfileChanges;
  String? lastDecidedRequestId;
  bool? lastDecisionApproved;

  @override
  Future<EmployeeRequest> submit({
    required String subject,
    required String description,
    String? type,
  }) async {
    lastSubmittedSubject = subject;
    if (submitError != null) throw submitError!;
    return buildTestRequest(subject: subject, description: description);
  }

  @override
  Future<EmployeeRequest> submitProfileChangeRequest(
    Map<String, dynamic> changes,
  ) async {
    lastProfileChanges = changes;
    if (submitError != null) throw submitError!;
    return buildTestRequest(
      subject: 'Profile update request',
      description: 'Pending changes',
      kind: 'profile_change',
      status: 'manager_approved',
    );
  }

  @override
  Future<List<EmployeeRequest>> getMine() async => mine;

  @override
  Future<List<EmployeeRequest>> getPendingManagerApproval() async =>
      pendingManagerApproval;

  @override
  Future<List<EmployeeRequest>> getPendingHrApproval() async =>
      pendingHrApproval;

  @override
  Future<List<EmployeeRequest>> getHistory() async => history;

  @override
  Future<List<EmployeeRequest>> getHistoryForMyTeam() async =>
      historyForMyTeam;

  @override
  Future<EmployeeRequest> approveAsManager(String requestId) async {
    lastDecidedRequestId = requestId;
    lastDecisionApproved = true;
    if (decisionError != null) throw decisionError!;
    return buildTestRequest(id: requestId, status: 'manager_approved');
  }

  @override
  Future<EmployeeRequest> rejectAsManager(
    String requestId, {
    String? reason,
  }) async {
    lastDecidedRequestId = requestId;
    lastDecisionApproved = false;
    if (decisionError != null) throw decisionError!;
    return buildTestRequest(id: requestId, status: 'rejected');
  }

  @override
  Future<EmployeeRequest> approveAsHr(String requestId) async {
    lastDecidedRequestId = requestId;
    lastDecisionApproved = true;
    if (decisionError != null) throw decisionError!;
    return buildTestRequest(id: requestId, status: 'completed');
  }

  @override
  Future<EmployeeRequest> rejectAsHr(String requestId, {String? reason}) async {
    lastDecidedRequestId = requestId;
    lastDecisionApproved = false;
    if (decisionError != null) throw decisionError!;
    return buildTestRequest(id: requestId, status: 'rejected');
  }
}
