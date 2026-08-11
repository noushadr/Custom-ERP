import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../requests/application/request_providers.dart';
import '../../../requests/domain/exceptions/request_exception.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/update_my_profile_input.dart';
import '../../domain/exceptions/employee_exception.dart';
import '../widgets/employee_avatar.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';

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
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountTitleController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _branchCodeController;
  late final TextEditingController _ibanController;
  late String? _photoUrl;
  late DateTime? _dateOfBirth;
  bool _isUploadingPhoto = false;
  bool _submitting = false;

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
    _bankNameController = TextEditingController(text: e.bankName);
    _accountTitleController = TextEditingController(text: e.accountTitle);
    _accountNumberController = TextEditingController(text: e.accountNumber);
    _branchCodeController = TextEditingController(text: e.branchCode);
    _ibanController = TextEditingController(text: e.iban);
  }

  @override
  void dispose() {
    _personalEmailController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _addressController.dispose();
    _bankNameController.dispose();
    _accountTitleController.dispose();
    _accountNumberController.dispose();
    _branchCodeController.dispose();
    _ibanController.dispose();
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
      ref.invalidate(myAuditLogProvider);
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final input = UpdateMyProfileInput(
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
      emergencyContactPhone: _emergencyPhoneController.text.trim().isEmpty
          ? null
          : _emergencyPhoneController.text.trim(),
      emergencyContactRelation:
          _emergencyRelationController.text.trim().isEmpty
          ? null
          : _emergencyRelationController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      bankName: _bankNameController.text.trim().isEmpty
          ? null
          : _bankNameController.text.trim(),
      accountTitle: _accountTitleController.text.trim().isEmpty
          ? null
          : _accountTitleController.text.trim(),
      accountNumber: _accountNumberController.text.trim().isEmpty
          ? null
          : _accountNumberController.text.trim(),
      branchCode: _branchCodeController.text.trim().isEmpty
          ? null
          : _branchCodeController.text.trim(),
      iban: _ibanController.text.trim().isEmpty
          ? null
          : _ibanController.text.trim(),
    );

    setState(() => _submitting = true);

    final messenger = ScaffoldMessenger.of(context);
    final authState = ref.read(authControllerProvider);
    final isSuperAdmin =
        authState is AuthAuthenticated && authState.user.role == 'Super Admin';

    try {
      if (isSuperAdmin) {
        // The top of the approval chain has nobody left to approve their
        // request, so their own edits apply immediately.
        await ref.read(employeeRepositoryProvider).updateMe(input);
        ref.invalidate(myProfileProvider);
        ref.invalidate(myAuditLogProvider);
        if (!mounted) return;
        Navigator.of(context).pop();
        messenger.showSnackBar(const SnackBar(content: Text('Profile updated.')));
      } else {
        await ref
            .read(requestRepositoryProvider)
            .submitProfileChangeRequest(input.toJson());
        ref.invalidate(myRequestsProvider);
        if (!mounted) return;
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Submitted for approval. Changes will apply once HR/Admin approves.',
            ),
          ),
        );
      }
    } on EmployeeException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } on RequestException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = _submitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FormSection(
                    child: Row(
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Change photo'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FormSection(
                    title: 'Contact',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _personalEmailController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Personal email',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final emailRegExp = RegExp(
                              r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$',
                            );
                            return emailRegExp.hasMatch(value.trim())
                                ? null
                                : 'Enter a valid email address';
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                          ),
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
                          decoration: const InputDecoration(
                            labelText: 'Address',
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FormSection(
                    title: 'Bank Information',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _bankNameController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Bank name',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _accountTitleController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Account title',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _accountNumberController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Account number',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _branchCodeController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Branch code',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ibanController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'IBAN',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FormSection(
                    title: 'Emergency contact',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emergencyNameController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emergencyPhoneController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emergencyRelationController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Relation',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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
      ),
    );
  }
}
