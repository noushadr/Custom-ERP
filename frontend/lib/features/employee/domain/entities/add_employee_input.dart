class AddEmployeeInput {
  const AddEmployeeInput({
    required this.companyEmail,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.designation,
    this.departmentId,
    this.reportingManagerId,
    this.joiningDate,
    this.workMode,
  });

  final String companyEmail;

  /// Set directly by the HR/Admin adding this employee — there is no
  /// self-signup, so nobody else ever picks this account's initial password.
  final String password;
  final String firstName;
  final String lastName;
  final String? designation;
  final String? departmentId;
  final String? reportingManagerId;
  final String? joiningDate;

  /// 'on_site', 'remote', or 'hybrid' — determines which onboarding
  /// checklist items apply. Defaults to on-site when omitted.
  final String? workMode;

  Map<String, dynamic> toJson() => {
    'companyEmail': companyEmail,
    'password': password,
    'firstName': firstName,
    'lastName': lastName,
    if (designation != null) 'designation': designation,
    if (departmentId != null) 'departmentId': departmentId,
    if (reportingManagerId != null) 'reportingManagerId': reportingManagerId,
    if (joiningDate != null) 'joiningDate': joiningDate,
    if (workMode != null) 'workMode': workMode,
  };
}
