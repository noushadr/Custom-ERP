import '../../../../core/config/app_config.dart';
import '../../../../shared/models/named_ref.dart';
import '../../domain/entities/employee.dart';

class EmployeeModel extends Employee {
  const EmployeeModel({
    required super.id,
    required super.userId,
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
    required super.reportingManager,
    required super.employmentType,
    required super.employmentStatus,
    required super.workMode,
    required super.joiningDate,
    required super.dateOfLeaving,
    required super.dateOfBirth,
    required super.personalEmail,
    required super.phoneNumber,
    required super.emergencyContactName,
    required super.emergencyContactPhone,
    required super.emergencyContactRelation,
    required super.address,
    required super.bankName,
    required super.accountTitle,
    required super.accountNumber,
    required super.branchCode,
    required super.iban,
    required super.skills,
    required super.certifications,
    required super.profileCompletionPercentage,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) => EmployeeModel(
    id: json['id'] as String,
    userId: json['userId'] as String,
    employeeCode: json['employeeCode'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    accountStatus: json['accountStatus'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    fullName: json['fullName'] as String,
    profilePhotoUrl: _resolvePhotoUrl(json['profilePhotoUrl'] as String?),
    designation: json['designation'] as String?,
    department: json['department'] == null
        ? null
        : NamedRef.fromJson(json['department'] as Map<String, dynamic>),
    reportingManager: _resolveReportingManager(
      json['reportingManager'] as Map<String, dynamic>?,
    ),
    employmentType: json['employmentType'] as String,
    employmentStatus: json['employmentStatus'] as String,
    workMode: json['workMode'] as String,
    joiningDate: json['joiningDate'] as String,
    dateOfLeaving: json['dateOfLeaving'] as String?,
    dateOfBirth: json['dateOfBirth'] as String?,
    personalEmail: json['personalEmail'] as String?,
    phoneNumber: json['phoneNumber'] as String?,
    emergencyContactName: json['emergencyContactName'] as String?,
    emergencyContactPhone: json['emergencyContactPhone'] as String?,
    emergencyContactRelation: json['emergencyContactRelation'] as String?,
    address: json['address'] as String?,
    bankName: json['bankName'] as String?,
    accountTitle: json['accountTitle'] as String?,
    accountNumber: json['accountNumber'] as String?,
    branchCode: json['branchCode'] as String?,
    iban: json['iban'] as String?,
    skills: (json['skills'] as List).cast<String>(),
    certifications: (json['certifications'] as List).cast<String>(),
    profileCompletionPercentage: json['profileCompletionPercentage'] as int,
  );

  /// The backend returns photo paths relative to itself (e.g.
  /// `/uploads/avatars/ZC-00001.jpg`) so the API response stays portable
  /// across environments; resolve it against our known API base here.
  static String? _resolvePhotoUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '${AppConfig.apiBaseUrl}$url';
  }

  static NamedRef? _resolveReportingManager(Map<String, dynamic>? json) {
    if (json == null) return null;
    return NamedRef(
      id: json['id'] as String,
      name: json['name'] as String,
      photoUrl: _resolvePhotoUrl(json['photoUrl'] as String?),
    );
  }
}
