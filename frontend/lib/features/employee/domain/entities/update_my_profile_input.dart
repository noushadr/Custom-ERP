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
    if (skills != null) 'skills': skills,
    if (certifications != null) 'certifications': certifications,
  };
}
