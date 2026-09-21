import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../../shared/widgets/responsive_card_row.dart';
import '../../../announcements/application/announcement_providers.dart';
import '../../../holidays/application/holiday_providers.dart';
import '../../../holidays/domain/entities/holiday.dart';
import '../../../notices/application/notice_providers.dart';
import '../../../notices/domain/exceptions/notice_exception.dart';
import '../../../tasks/application/task_providers.dart';
import '../../../tasks/domain/entities/task_status.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/upcoming_birthday.dart';
import '../../domain/entities/upcoming_work_anniversary.dart';
import '../widgets/company_notices_section.dart';
import '../widgets/employee_avatar.dart';
import 'employee_profile_page.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: _DashboardStats(),
    );
  }
}

// The Overview stat tiles (Avg. Profile Completion, Notice Period, Pending
// Performance Reviews) moved to the Employees page — see
// `_EmployeeStatsSection` in `employee_directory_page.dart`. The New Hires
// chart and Employees by Department breakdown that used to follow them were
// removed outright per explicit instruction, replaced with the four
// "spotlight" cards below. "Post notice" stays here; it's an action, not a
// stat.
class _DashboardStats extends StatelessWidget {
  const _DashboardStats();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveCardRow(
            minItemWidth: 240,
            spacing: 12,
            children: [
              _EmployeeOfMonthCard(),
              _LastBirthdayCard(),
              _UpcomingBirthdayCard(),
              _UpcomingWorkAnniversaryCard(),
              _UpcomingHolidayCard(),
              _TasksSummaryCard(),
            ],
          ),
          const SizedBox(height: 18),
          CompanyNoticesSection(
            trailing: FilledButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const _PostNoticeDialog(),
              ),
              icon: const Icon(Icons.campaign_outlined, size: 16),
              label: const Text('Post notice'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared chrome for every spotlight card — an icon+title header over
/// whatever content the specific card provides, matching the
/// icon-then-title layout `PieChartPanel`/`TopBreakdownPanel` already use
/// elsewhere in this app.
class _SpotlightCard extends StatelessWidget {
  const _SpotlightCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// A person's avatar + name + one caption line — the shared body for every
/// spotlight card about a specific employee (Employee of the Month, Last/
/// Upcoming Birthday). Tapping opens that employee's own profile — every
/// spotlight card links to a real person, not just a label.
class _SpotlightPerson extends StatelessWidget {
  const _SpotlightPerson({
    required this.employeeId,
    required this.fullName,
    required this.caption,
    this.photoUrl,
  });

  final String employeeId;
  final String fullName;
  final String caption;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmployeeProfilePage(employeeId: employeeId),
        ),
      ),
      child: Row(
        children: [
          EmployeeAvatar(fullName: fullName, photoUrl: photoUrl, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightEmpty extends StatelessWidget {
  const _SpotlightEmpty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _EmployeeOfMonthCard extends ConsumerWidget {
  const _EmployeeOfMonthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(todayAnnouncementsProvider);

    return _SpotlightCard(
      title: 'Employee of the Month',
      icon: Icons.emoji_events_outlined,
      color: AppColors.success,
      child: announcementsAsync.when(
        loading: () => const _SpotlightEmpty('Loading…'),
        error: (_, _) => const _SpotlightEmpty('Could not load.'),
        data: (announcements) {
          final employeeOfTheMonth = announcements.employeeOfTheMonth;
          if (employeeOfTheMonth == null) {
            return const _SpotlightEmpty('No Employee of the Month right now.');
          }
          return _SpotlightPerson(
            employeeId: employeeOfTheMonth.employeeId,
            fullName: employeeOfTheMonth.fullName,
            photoUrl: employeeOfTheMonth.profilePhotoUrl,
            caption: 'Congrats! 🏆',
          );
        },
      ),
    );
  }
}

class _LastBirthdayCard extends ConsumerWidget {
  const _LastBirthdayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotlightAsync = ref.watch(birthdaySpotlightProvider);

    return _SpotlightCard(
      title: 'Last Birthday',
      icon: Icons.cake_outlined,
      color: AppColors.secondary,
      child: spotlightAsync.when(
        loading: () => const _SpotlightEmpty('Loading…'),
        error: (_, _) => const _SpotlightEmpty('Could not load.'),
        data: (spotlight) {
          final last = spotlight.last;
          if (last == null) {
            return const _SpotlightEmpty('No recent birthdays.');
          }
          return _SpotlightPerson(
            employeeId: last.employeeId,
            fullName: last.fullName,
            photoUrl: last.profilePhotoUrl,
            caption: '${formatMonthDay(last.dateOfBirth)} · ${_agoLabel(last)}',
          );
        },
      ),
    );
  }

  String _agoLabel(UpcomingBirthday birthday) {
    final daysAgo = -birthday.daysUntil;
    return daysAgo == 1 ? '1 day ago' : '$daysAgo days ago';
  }
}

class _UpcomingBirthdayCard extends ConsumerWidget {
  const _UpcomingBirthdayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotlightAsync = ref.watch(birthdaySpotlightProvider);

    return _SpotlightCard(
      title: 'Upcoming Birthday',
      icon: Icons.cake_outlined,
      color: AppColors.secondary,
      child: spotlightAsync.when(
        loading: () => const _SpotlightEmpty('Loading…'),
        error: (_, _) => const _SpotlightEmpty('Could not load.'),
        data: (spotlight) {
          final upcoming = spotlight.upcoming;
          if (upcoming == null) {
            return const _SpotlightEmpty('No upcoming birthdays.');
          }
          return _SpotlightPerson(
            employeeId: upcoming.employeeId,
            fullName: upcoming.fullName,
            photoUrl: upcoming.profilePhotoUrl,
            caption: upcoming.daysUntil == 0
                ? 'Today! 🎉'
                : '${formatMonthDay(upcoming.dateOfBirth)} · ${_inLabel(upcoming.daysUntil)}',
          );
        },
      ),
    );
  }

  String _inLabel(int daysUntil) =>
      daysUntil == 1 ? 'in 1 day' : 'in $daysUntil days';
}

/// Unlike the birthday cards (always exactly one person), a work-anniversary
/// month can genuinely have several employees hitting theirs together — this
/// stacks one `_SpotlightPerson` row per anniversary in that month instead of
/// showing just the single soonest one.
class _UpcomingWorkAnniversaryCard extends ConsumerWidget {
  const _UpcomingWorkAnniversaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotlightAsync = ref.watch(workAnniversarySpotlightProvider);

    return _SpotlightCard(
      title: 'Upcoming Work Anniversary',
      icon: Icons.military_tech_outlined,
      color: AppColors.accentTeal,
      child: spotlightAsync.when(
        loading: () => const _SpotlightEmpty('Loading…'),
        error: (_, _) => const _SpotlightEmpty('Could not load.'),
        data: (anniversaries) {
          if (anniversaries.isEmpty) {
            return const _SpotlightEmpty('No upcoming work anniversaries.');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < anniversaries.length; i++) ...[
                _SpotlightPerson(
                  employeeId: anniversaries[i].employeeId,
                  fullName: anniversaries[i].fullName,
                  photoUrl: anniversaries[i].profilePhotoUrl,
                  caption: _caption(anniversaries[i]),
                ),
                if (i < anniversaries.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }

  String _caption(UpcomingWorkAnniversary anniversary) {
    final years = anniversary.yearsOfService;
    final yearsLabel = years == 1 ? '1 year' : '$years years';
    if (anniversary.daysUntil == 0) return '$yearsLabel · Today! 🎉';
    return '$yearsLabel · ${_inLabel(anniversary.daysUntil)}';
  }

  String _inLabel(int daysUntil) =>
      daysUntil == 1 ? 'in 1 day' : 'in $daysUntil days';
}

class _UpcomingHolidayCard extends ConsumerWidget {
  const _UpcomingHolidayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holidaysAsync = ref.watch(holidaysProvider);

    return _SpotlightCard(
      title: 'Upcoming Public Holiday',
      icon: Icons.festival_outlined,
      color: AppColors.warning,
      child: holidaysAsync.when(
        loading: () => const _SpotlightEmpty('Loading…'),
        error: (_, _) => const _SpotlightEmpty('Could not load.'),
        data: (holidays) {
          final next = _nextUpcoming(holidays);
          if (next == null) {
            return const _SpotlightEmpty('No upcoming holiday scheduled.');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                next.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '${formatDisplayDate(next.date)} · ${_inLabel(next.date)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          );
        },
      ),
    );
  }

  /// The earliest holiday whose date is today or later, or null if every
  /// holiday on file has already passed.
  Holiday? _nextUpcoming(List<Holiday> holidays) {
    final today = DateTime.now();
    final todayIso =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    final upcoming =
        holidays.where((h) => h.date.compareTo(todayIso) >= 0).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  String _inLabel(String isoDate) {
    final today = DateTime.now();
    final todayAtMidnight = DateTime(today.year, today.month, today.day);
    final date = DateTime.parse(isoDate);
    final daysUntil = date.difference(todayAtMidnight).inDays;
    if (daysUntil == 0) return 'Today';
    return daysUntil == 1 ? 'in 1 day' : 'in $daysUntil days';
  }
}

/// Company-wide task counts — `teamTasksProvider` returns every task in the
/// company for a `tasks.manage` holder (Super Admin/HR-Manager, exactly who
/// sees this page), so no separate summary endpoint is needed. "Pending /
/// In Progress" groups every still-open status together (todo, pending, and
/// in-progress) since from a dashboard glance they're all "not done yet";
/// cancelled tasks count toward the total but not either bucket, same as
/// they're excluded from the Tasks page's own board columns.
class _TasksSummaryCard extends ConsumerWidget {
  const _TasksSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(teamTasksProvider);

    return _SpotlightCard(
      title: 'Tasks',
      icon: Icons.checklist_outlined,
      color: AppColors.primary,
      child: tasksAsync.when(
        loading: () => const _SpotlightEmpty('Loading…'),
        error: (_, _) => const _SpotlightEmpty('Could not load.'),
        data: (tasks) {
          if (tasks.isEmpty) return const _SpotlightEmpty('No tasks yet.');
          final pendingOrInProgress = tasks
              .where(
                (t) =>
                    t.status == TaskStatus.todo ||
                    t.status == TaskStatus.pending ||
                    t.status == TaskStatus.inProgress,
              )
              .length;
          final done = tasks
              .where((t) => t.status == TaskStatus.completed)
              .length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _TaskStatRow(
                label: 'Total',
                value: tasks.length,
                color: AppColors.textPrimary,
              ),
              const SizedBox(height: 8),
              _TaskStatRow(
                label: 'Pending / In Progress',
                value: pendingOrInProgress,
                color: AppColors.warning,
              ),
              const SizedBox(height: 8),
              _TaskStatRow(
                label: 'Done',
                value: done,
                color: AppColors.success,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TaskStatRow extends StatelessWidget {
  const _TaskStatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _PostNoticeDialog extends ConsumerStatefulWidget {
  const _PostNoticeDialog();

  @override
  ConsumerState<_PostNoticeDialog> createState() => _PostNoticeDialogState();
}

class _PostNoticeDialogState extends ConsumerState<_PostNoticeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(noticeRepositoryProvider)
          .create(title: _titleController.text, body: _bodyController.text);
      ref.invalidate(noticeListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on NoticeException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Post a company notice'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Message'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Post'),
        ),
      ],
    );
  }
}
