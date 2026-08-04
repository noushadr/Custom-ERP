/// A lightweight (id, name) reference — used for department/team dropdowns
/// and for the department/team shown on an employee record.
class NamedRef {
  const NamedRef({required this.id, required this.name});

  final String id;
  final String name;

  factory NamedRef.fromJson(Map<String, dynamic> json) =>
      NamedRef(id: json['id'] as String, name: json['name'] as String);
}
