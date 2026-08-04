class InviteEmployeeInput {
  const InviteEmployeeInput({
    required this.companyEmail,
    required this.firstName,
    required this.lastName,
    this.designation,
    this.departmentId,
    this.teamId,
    this.reportingManagerId,
    this.joiningDate,
  });

  final String companyEmail;
  final String firstName;
  final String lastName;
  final String? designation;
  final String? departmentId;
  final String? teamId;
  final String? reportingManagerId;
  final String? joiningDate;

  Map<String, dynamic> toJson() => {
    'companyEmail': companyEmail,
    'firstName': firstName,
    'lastName': lastName,
    if (designation != null) 'designation': designation,
    if (departmentId != null) 'departmentId': departmentId,
    if (teamId != null) 'teamId': teamId,
    if (reportingManagerId != null) 'reportingManagerId': reportingManagerId,
    if (joiningDate != null) 'joiningDate': joiningDate,
  };
}
