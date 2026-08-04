import '../../../../shared/models/named_ref.dart';

class Employee {
  const Employee({
    required this.id,
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
    required this.team,
    required this.reportingManager,
    required this.employmentType,
    required this.employmentStatus,
    required this.joiningDate,
    required this.personalEmail,
    required this.phoneNumber,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.emergencyContactRelation,
    required this.address,
    required this.skills,
    required this.certifications,
    required this.profileCompletionPercentage,
  });

  final String id;
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
  final NamedRef? team;
  final NamedRef? reportingManager;
  final String employmentType;
  final String employmentStatus;
  final String joiningDate;
  final String? personalEmail;
  final String? phoneNumber;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final String? address;
  final List<String> skills;
  final List<String> certifications;
  final int profileCompletionPercentage;
}
