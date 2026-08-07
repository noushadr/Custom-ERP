class UpdateMyProfileInput {
  const UpdateMyProfileInput({
    this.profilePhotoUrl,
    this.dateOfBirth,
    this.personalEmail,
    this.phoneNumber,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.address,
    this.bankName,
    this.accountTitle,
    this.accountNumber,
    this.branchCode,
    this.iban,
    this.skills,
    this.certifications,
  });

  final String? profilePhotoUrl;
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
  final List<String>? skills;
  final List<String>? certifications;

  Map<String, dynamic> toJson() => {
    if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
    if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
    if (personalEmail != null) 'personalEmail': personalEmail,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    if (emergencyContactName != null)
      'emergencyContactName': emergencyContactName,
    if (emergencyContactPhone != null)
      'emergencyContactPhone': emergencyContactPhone,
    if (emergencyContactRelation != null)
      'emergencyContactRelation': emergencyContactRelation,
    if (address != null) 'address': address,
    if (bankName != null) 'bankName': bankName,
    if (accountTitle != null) 'accountTitle': accountTitle,
    if (accountNumber != null) 'accountNumber': accountNumber,
    if (branchCode != null) 'branchCode': branchCode,
    if (iban != null) 'iban': iban,
    if (skills != null) 'skills': skills,
    if (certifications != null) 'certifications': certifications,
  };
}
