import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/employee_providers.dart';
import '../../application/invite_employee_controller.dart';
import '../../application/invite_employee_state.dart';
import '../../domain/entities/invite_employee_input.dart';

final _companyEmailRegExp = RegExp(r'^[a-z]+\.[a-z]+@zeracreative\.com$');

class InviteEmployeePage extends ConsumerStatefulWidget {
  const InviteEmployeePage({super.key});

  @override
  ConsumerState<InviteEmployeePage> createState() =>
      _InviteEmployeePageState();
}

class _InviteEmployeePageState extends ConsumerState<InviteEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _designationController = TextEditingController();
  String? _departmentId;
  String? _teamId;

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(inviteEmployeeControllerProvider.notifier)
        .submit(
          InviteEmployeeInput(
            companyEmail: _emailController.text.trim(),
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            designation: _designationController.text.trim().isEmpty
                ? null
                : _designationController.text.trim(),
            departmentId: _departmentId,
            teamId: _teamId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inviteEmployeeControllerProvider);

    if (state is InviteSuccess) {
      return _InviteSuccessView(
        employeeName: state.employee.fullName,
        temporaryPassword: state.temporaryPassword,
      );
    }

    final isSubmitting = state is InviteSubmitting;
    final errorMessage = state is InviteError ? state.message : null;
    final departmentsAsync = ref.watch(departmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Invite Employee')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (errorMessage != null) ...[
                  Text(
                    errorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _emailController,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Company email',
                    hintText: 'firstname.lastname@zeracreative.com',
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) return 'Company email is required';
                    if (!_companyEmailRegExp.hasMatch(trimmed)) {
                      return 'Must match firstname.lastname@zeracreative.com';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameController,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(labelText: 'First name'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'First name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Last name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _designationController,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Designation (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                departmentsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text('Could not load departments.'),
                  data: (departments) => DropdownButtonFormField<String>(
                    initialValue: _departmentId,
                    decoration: const InputDecoration(
                      labelText: 'Department (optional)',
                    ),
                    items: [
                      for (final department in departments)
                        DropdownMenuItem(
                          value: department.id,
                          child: Text(department.name),
                        ),
                    ],
                    onChanged: isSubmitting
                        ? null
                        : (value) => setState(() {
                            _departmentId = value;
                            _teamId = null;
                          }),
                  ),
                ),
                if (_departmentId != null) ...[
                  const SizedBox(height: 16),
                  Consumer(
                    builder: (context, ref, _) {
                      final teamsAsync = ref.watch(
                        teamsProvider(_departmentId),
                      );
                      return teamsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const Text('Could not load teams.'),
                        data: (teams) => DropdownButtonFormField<String>(
                          initialValue: _teamId,
                          decoration: const InputDecoration(
                            labelText: 'Team (optional)',
                          ),
                          items: [
                            for (final team in teams)
                              DropdownMenuItem(
                                value: team.id,
                                child: Text(team.name),
                              ),
                          ],
                          onChanged: isSubmitting
                              ? null
                              : (value) => setState(() => _teamId = value),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: isSubmitting ? null : _submit,
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send invite'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteSuccessView extends ConsumerWidget {
  const _InviteSuccessView({
    required this.employeeName,
    required this.temporaryPassword,
  });

  final String employeeName;
  final String temporaryPassword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Employee')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                '$employeeName has been invited.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Share this temporary password with them directly — there is no email invite yet, so this is the only place it will be shown.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SelectableText(
                      temporaryPassword,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      tooltip: 'Copy',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: temporaryPassword),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(employeeListProvider);
                  Navigator.of(context).pop();
                },
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
