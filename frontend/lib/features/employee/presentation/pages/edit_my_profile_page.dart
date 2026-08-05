import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/employee_providers.dart';
import '../../application/update_profile_controller.dart';
import '../../application/update_profile_state.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/update_my_profile_input.dart';
import '../../domain/exceptions/employee_exception.dart';
import '../widgets/employee_avatar.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/tag_input.dart';

class EditMyProfilePage extends ConsumerStatefulWidget {
  const EditMyProfilePage({super.key, required this.employee});

  final Employee employee;

  @override
  ConsumerState<EditMyProfilePage> createState() => _EditMyProfilePageState();
}

class _EditMyProfilePageState extends ConsumerState<EditMyProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _personalEmailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyPhoneController;
  late final TextEditingController _emergencyRelationController;
  late final TextEditingController _addressController;
  late List<String> _skills;
  late List<String> _certifications;
  late String? _photoUrl;
  late DateTime? _dateOfBirth;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _photoUrl = e.profilePhotoUrl;
    _dateOfBirth = e.dateOfBirth == null
        ? null
        : DateTime.tryParse(e.dateOfBirth!);
    _personalEmailController = TextEditingController(text: e.personalEmail);
    _phoneController = TextEditingController(text: e.phoneNumber);
    _emergencyNameController = TextEditingController(
      text: e.emergencyContactName,
    );
    _emergencyPhoneController = TextEditingController(
      text: e.emergencyContactPhone,
    );
    _emergencyRelationController = TextEditingController(
      text: e.emergencyContactRelation,
    );
    _addressController = TextEditingController(text: e.address);
    _skills = List.of(e.skills);
    _certifications = List.of(e.certifications);
  }

  @override
  void dispose() {
    _personalEmailController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final picked = result?.files.single;
    if (picked?.bytes == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final employee = await ref
          .read(employeeRepositoryProvider)
          .uploadMyPhoto(picked!.bytes!, picked.name);
      ref.invalidate(myProfileProvider);
      if (!mounted) return;
      setState(() => _photoUrl = employee.profilePhotoUrl);
    } on EmployeeException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(updateProfileControllerProvider.notifier)
        .submit(
          UpdateMyProfileInput(
            dateOfBirth: _dateOfBirth == null ? null : _isoDate(_dateOfBirth!),
            personalEmail: _personalEmailController.text.trim().isEmpty
                ? null
                : _personalEmailController.text.trim(),
            phoneNumber: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            emergencyContactName: _emergencyNameController.text.trim().isEmpty
                ? null
                : _emergencyNameController.text.trim(),
            emergencyContactPhone:
                _emergencyPhoneController.text.trim().isEmpty
                ? null
                : _emergencyPhoneController.text.trim(),
            emergencyContactRelation:
                _emergencyRelationController.text.trim().isEmpty
                ? null
                : _emergencyRelationController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            skills: _skills,
            certifications: _certifications,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UpdateProfileState>(updateProfileControllerProvider, (
      previous,
      next,
    ) {
      if (next is UpdateProfileSuccess) {
        ref.invalidate(myProfileProvider);
        Navigator.of(context).pop();
      } else if (next is UpdateProfileError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    final state = ref.watch(updateProfileControllerProvider);
    final isSubmitting = state is UpdateProfileSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    EmployeeAvatar(
                      fullName: widget.employee.fullName,
                      photoUrl: _photoUrl,
                      radius: 32,
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: (isSubmitting || _isUploadingPhoto)
                          ? null
                          : _pickAndUploadPhoto,
                      child: _isUploadingPhoto
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Change photo'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _personalEmailController,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(labelText: 'Personal email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final emailRegExp = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
                    return emailRegExp.hasMatch(value.trim())
                        ? null
                        : 'Enter a valid email address';
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: isSubmitting ? null : _pickDateOfBirth,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of birth',
                    ),
                    child: Text(
                      _dateOfBirth == null
                          ? '—'
                          : formatDisplayDate(_isoDate(_dateOfBirth!)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                Text(
                  'Emergency contact',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emergencyNameController,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emergencyPhoneController,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emergencyRelationController,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(labelText: 'Relation'),
                ),
                const SizedBox(height: 24),
                TagInput(
                  label: 'Skills',
                  values: _skills,
                  enabled: !isSubmitting,
                  onChanged: (values) => setState(() => _skills = values),
                ),
                const SizedBox(height: 24),
                TagInput(
                  label: 'Certifications',
                  values: _certifications,
                  enabled: !isSubmitting,
                  onChanged: (values) =>
                      setState(() => _certifications = values),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: isSubmitting ? null : _submit,
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
