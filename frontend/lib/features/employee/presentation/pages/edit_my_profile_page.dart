import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/employee_providers.dart';
import '../../application/update_profile_controller.dart';
import '../../application/update_profile_state.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/update_my_profile_input.dart';
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

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(updateProfileControllerProvider.notifier)
        .submit(
          UpdateMyProfileInput(
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
