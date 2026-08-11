/// Fields an HR/Admin can change on someone else's record, in addition to
/// everything an employee can edit on their own profile. Unlike self-service
/// edits, this always sends the full field set (nulling out cleared values)
/// since the HR form shows and replaces the complete record, not a partial
/// update.
class UpdateEmployeeInput {
  const UpdateEmployeeInput({
    this.firstName,
    this.lastName,
    this.designation,
    this.departmentId,
    this.teamId,
    this.reportingManagerId,
    this.employmentType,
    this.employmentStatus,
    this.workMode,
    this.joiningDate,
    this.dateOfLeaving,
    this.personalEmail,
    this.phoneNumber,
    this.dateOfBirth,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.address,
    this.bankName,
    this.accountTitle,
    this.accountNumber,
    this.branchCode,
    this.iban,
  });

  final String? firstName;
  final String? lastName;
  final String? designation;
  final String? departmentId;
  final String? teamId;
  final String? reportingManagerId;
  final String? employmentType;
  final String? employmentStatus;
  final String? workMode;
  final String? joiningDate;
  final String? dateOfLeaving;
  final String? personalEmail;
  final String? phoneNumber;
  final String? dateOfBirth;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final String? address;
  final String? bankName;
  final String? accountTitle;
  final String? accountNumber;
  final String? branchCode;
  final String? iban;

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'designation': designation,
    'departmentId': departmentId,
    'teamId': teamId,
    'reportingManagerId': reportingManagerId,
    'employmentType': employmentType,
    'employmentStatus': employmentStatus,
    'workMode': workMode,
    'joiningDate': joiningDate,
    'dateOfLeaving': dateOfLeaving,
    'personalEmail': personalEmail,
    'phoneNumber': phoneNumber,
    'dateOfBirth': dateOfBirth,
    'emergencyContactName': emergencyContactName,
    'emergencyContactPhone': emergencyContactPhone,
    'emergencyContactRelation': emergencyContactRelation,
    'address': address,
    'bankName': bankName,
    'accountTitle': accountTitle,
    'accountNumber': accountNumber,
    'branchCode': branchCode,
    'iban': iban,
  };
}
