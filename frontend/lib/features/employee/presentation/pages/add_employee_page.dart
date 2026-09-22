import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/employee_providers.dart';
import '../../application/add_employee_controller.dart';
import '../../application/add_employee_state.dart';
import '../../domain/entities/add_employee_input.dart';

final _companyEmailRegExp = RegExp(r'^[^@\s]+@zeracreative\.com$');

const _companyEmailDomain = '@zeracreative.com';

const _workModes = {
  'on_site': 'On-site',
  'remote': 'Remote',
  'hybrid': 'Hybrid',
};

/// HR/Admin add an employee directly from this form — there is no
/// self-signup and no email invite. The admin sets the account's initial
/// password directly here, rather than the system generating one to hand
/// over separately.
class AddEmployeePage extends ConsumerStatefulWidget {
  const AddEmployeePage({super.key});

  @override
  ConsumerState<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends ConsumerState<AddEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: _companyEmailDomain)
    ..selection = const TextSelection.collapsed(offset: 0);
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _designationController = TextEditingController();
  String? _departmentId;
  String _workMode = 'on_site';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(addEmployeeControllerProvider.notifier)
        .submit(
          AddEmployeeInput(
            companyEmail: _emailController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            designation: _designationController.text.trim().isEmpty
                ? null
                : _designationController.text.trim(),
            departmentId: _departmentId,
            workMode: _workMode,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addEmployeeControllerProvider);

    if (state is AddEmployeeSuccess) {
      return _AddEmployeeSuccessView(employeeName: state.employee.fullName);
    }

    final isSubmitting = state is AddEmployeeSubmitting;
    final errorMessage = state is AddEmployeeError ? state.message : null;
    final departmentsAsync = ref.watch(departmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Employee')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                          hintText: 'name@zeracreative.com',
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty ||
                              trimmed == _companyEmailDomain) {
                            return 'Company email is required';
                          }
                          if (!_companyEmailRegExp.hasMatch(trimmed)) {
                            return 'Must be a @zeracreative.com address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !isSubmitting,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (value.length < 8) {
                            return 'Must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _firstNameController,
                        enabled: !isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'First name',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'First name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lastNameController,
                        enabled: !isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Last name',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
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
                        error: (_, _) =>
                            const Text('Could not load departments.'),
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
                              : (value) =>
                                    setState(() => _departmentId = value),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _workMode,
                        decoration: const InputDecoration(
                          labelText: 'Work mode',
                        ),
                        items: [
                          for (final entry in _workModes.entries)
                            DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                        ],
                        onChanged: isSubmitting
                            ? null
                            : (value) => setState(() => _workMode = value!),
                      ),
                      const SizedBox(height: 22),
                      ElevatedButton(
                        onPressed: isSubmitting ? null : _submit,
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Add'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddEmployeeSuccessView extends ConsumerWidget {
  const _AddEmployeeSuccessView({required this.employeeName});

  final String employeeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Employee')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                '$employeeName has been added.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'They can sign in right away with the company email and '
                'password you set.',
                textAlign: TextAlign.center,
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
