import '../../../../shared/models/named_ref.dart';
import '../../domain/entities/employee.dart';

class EmployeeModel extends Employee {
  const EmployeeModel({
    required super.id,
    required super.employeeCode,
    required super.email,
    required super.role,
    required super.accountStatus,
    required super.firstName,
    required super.lastName,
    required super.fullName,
    required super.profilePhotoUrl,
    required super.designation,
    required super.department,
    required super.team,
    required super.reportingManagerId,
    required super.employmentType,
    required super.employmentStatus,
    required super.joiningDate,
    required super.personalEmail,
    required super.phoneNumber,
    required super.emergencyContactName,
    required super.emergencyContactPhone,
    required super.emergencyContactRelation,
    required super.address,
    required super.skills,
    required super.certifications,
    required super.profileCompletionPercentage,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) => EmployeeModel(
    id: json['id'] as String,
    employeeCode: json['employeeCode'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    accountStatus: json['accountStatus'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    fullName: json['fullName'] as String,
    profilePhotoUrl: json['profilePhotoUrl'] as String?,
    designation: json['designation'] as String?,
    department: json['department'] == null
        ? null
        : NamedRef.fromJson(json['department'] as Map<String, dynamic>),
    team: json['team'] == null
        ? null
        : NamedRef.fromJson(json['team'] as Map<String, dynamic>),
    reportingManagerId: json['reportingManagerId'] as String?,
    employmentType: json['employmentType'] as String,
    employmentStatus: json['employmentStatus'] as String,
    joiningDate: json['joiningDate'] as String,
    personalEmail: json['personalEmail'] as String?,
    phoneNumber: json['phoneNumber'] as String?,
    emergencyContactName: json['emergencyContactName'] as String?,
    emergencyContactPhone: json['emergencyContactPhone'] as String?,
    emergencyContactRelation: json['emergencyContactRelation'] as String?,
    address: json['address'] as String?,
    skills: (json['skills'] as List).cast<String>(),
    certifications: (json['certifications'] as List).cast<String>(),
    profileCompletionPercentage: json['profileCompletionPercentage'] as int,
  );
}
