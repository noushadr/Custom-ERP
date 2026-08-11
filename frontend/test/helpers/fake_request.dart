import 'package:zera_erp/features/requests/domain/entities/employee_request.dart';
import 'package:zera_erp/features/requests/domain/repositories/request_repository.dart';

EmployeeRequest buildTestRequest({
  String id = 'request-1',
  String requesterId = 'employee-1',
  String requesterName = 'Jane Doe',
  String subject = 'New laptop',
  String description = 'Current one is broken.',
  String status = 'submitted',
}) {
  return EmployeeRequest(
    id: id,
    requesterId: requesterId,
    requesterName: requesterName,
    subject: subject,
    description: description,
    status: status,
    createdAt: DateTime(2026, 1, 1),
  );
}

class FakeRequestRepository implements RequestRepository {
  FakeRequestRepository({
    this.mine = const [],
    this.pendingManagerApproval = const [],
    this.pendingHrApproval = const [],
    this.submitError,
    this.decisionError,
  });

  final List<EmployeeRequest> mine;
  final List<EmployeeRequest> pendingManagerApproval;
  final List<EmployeeRequest> pendingHrApproval;
  final Object? submitError;
  final Object? decisionError;

  String? lastSubmittedSubject;
  String? lastItemName;
  String? lastItemPurpose;
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
  Future<EmployeeRequest> submitItemRequest({
    required String itemName,
    required String purpose,
  }) async {
    lastItemName = itemName;
    lastItemPurpose = purpose;
    if (submitError != null) throw submitError!;
    return buildTestRequest(
      subject: 'Item request: $itemName',
      description: purpose,
    );
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
