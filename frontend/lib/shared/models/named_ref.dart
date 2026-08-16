/// A lightweight (id, name) reference — used for department dropdowns and
/// for the department/reporting-manager shown on an employee record.
/// [photoUrl] is only ever populated for reporting managers.
class NamedRef {
  const NamedRef({required this.id, required this.name, this.photoUrl});

  final String id;
  final String name;
  final String? photoUrl;

  factory NamedRef.fromJson(Map<String, dynamic> json) => NamedRef(
    id: json['id'] as String,
    name: json['name'] as String,
    photoUrl: json['photoUrl'] as String?,
  );
}
