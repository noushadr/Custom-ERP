import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/employee.dart';
import '../widgets/employee_avatar.dart';
import 'edit_my_profile_page.dart';

/// Shows an employee's profile. Pass null for [employeeId] to view the
/// current user's own profile.
class EmployeeProfilePage extends ConsumerWidget {
  const EmployeeProfilePage({super.key, required this.employeeId});

  final String? employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = employeeId == null
        ? ref.watch(myProfileProvider)
        : ref.watch(employeeDetailProvider(employeeId!));

    return Scaffold(
      appBar: AppBar(title: const Text('Employee Profile')),
      body: employeeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(
          child: Text('Could not load this profile.'),
        ),
        data: (employee) => _ProfileBody(employee: employee),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isOwnProfile =
        authState is AuthAuthenticated && authState.user.email == employee.email;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                EmployeeAvatar(
                  fullName: employee.fullName,
                  photoUrl: employee.profilePhotoUrl,
                  radius: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.fullName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        employee.designation ?? employee.role,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (isOwnProfile)
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditMyProfilePage(employee: employee),
                      ),
                    ),
                    child: const Text('Edit'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: employee.profileCompletionPercentage / 100,
            ),
            const SizedBox(height: 4),
            Text(
              'Profile ${employee.profileCompletionPercentage}% complete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Work',
              rows: {
                'Employee ID': employee.employeeCode,
                'Department': employee.department?.name ?? '—',
                'Team': employee.team?.name ?? '—',
                'Employment type': employee.employmentType,
                'Employment status': employee.employmentStatus,
                'Joining date': employee.joiningDate,
              },
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Contact',
              rows: {
                'Company email': employee.email,
                'Personal email': employee.personalEmail ?? '—',
                'Phone': employee.phoneNumber ?? '—',
                'Address': employee.address ?? '—',
              },
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Emergency contact',
              rows: {
                'Name': employee.emergencyContactName ?? '—',
                'Phone': employee.emergencyContactPhone ?? '—',
                'Relation': employee.emergencyContactRelation ?? '—',
              },
            ),
            const SizedBox(height: 24),
            _ChipsSection(title: 'Skills', values: employee.skills),
            const SizedBox(height: 24),
            _ChipsSection(
              title: 'Certifications',
              values: employee.certifications,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final entry in rows.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 160,
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(child: Text(entry.value)),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChipsSection extends StatelessWidget {
  const _ChipsSection({required this.title, required this.values});

  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (values.isEmpty)
          const Text('—')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final value in values) Chip(label: Text(value))],
          ),
      ],
    );
  }
}
