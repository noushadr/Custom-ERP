import '../../../../shared/models/named_ref.dart';

class Employee {
  const Employee({
    required this.id,
    required this.userId,
    required this.employeeCode,
    required this.email,
    required this.role,
    required this.accountStatus,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.profilePhotoUrl,
    required this.designation,
    required this.department,
    required this.reportingManager,
    required this.employmentType,
    required this.employmentStatus,
    required this.workMode,
    required this.joiningDate,
    required this.dateOfLeaving,
    required this.probationEndDate,
    required this.probationStatus,
    required this.dateOfBirth,
    required this.personalEmail,
    required this.phoneNumber,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.emergencyContactRelation,
    required this.address,
    required this.bankName,
    required this.accountTitle,
    required this.accountNumber,
    required this.branchCode,
    required this.iban,
    required this.skills,
    required this.certifications,
    required this.profileCompletionPercentage,
  });

  final String id;
  final String userId;
  final String employeeCode;
  final String email;
  final String role;
  final String accountStatus;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? profilePhotoUrl;
  final String? designation;
  final NamedRef? department;
  final NamedRef? reportingManager;
  final String employmentType;
  final String employmentStatus;
  final String workMode;
  final String joiningDate;
  final String? dateOfLeaving;

  /// Every employee goes through probation, but not for a fixed company-wide
  /// duration — this is that employee's own end date, `null` if it was
  /// never set (e.g. a pre-existing record from before this field existed).
  final String? probationEndDate;

  /// Computed backend-side from [probationEndDate] against today —
  /// `'on_probation'` / `'completed'` / `null` (no probation period on
  /// file). Never derive this client-side; the backend is the single source
  /// of truth for "today" to avoid client-clock drift.
  final String? probationStatus;
  final String? dateOfBirth;
  final String? personalEmail;
  final String? phoneNumber;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final String? address;
  final String? bankName;
  final String? accountTitle;
  final String? accountNumber;
  final String? branchCode;
  final String? iban;
  final List<String> skills;
  final List<String> certifications;
  final int profileCompletionPercentage;
}

extension EmployeeStatusChecks on Employee {
  /// False once someone has resigned or been terminated — used to keep
  /// former employees out of the org chart and out of "current" counts.
  bool get isCurrentEmployee =>
      employmentStatus != 'resigned' && employmentStatus != 'terminated';
}
