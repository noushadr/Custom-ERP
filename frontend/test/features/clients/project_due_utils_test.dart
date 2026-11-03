import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/clients/domain/entities/project_status.dart';
import 'package:zera_erp/features/clients/domain/entities/project_type.dart';
import 'package:zera_erp/features/clients/presentation/utils/project_due_utils.dart';

import '../../helpers/fake_clients.dart';

void main() {
  final today = DateTime(2026, 11, 3);

  test('a one-time project uses its deadline, a retainer its renewal', () {
    final oneTime = buildTestProject(
      type: ProjectType.oneTime,
      endDate: '2026-11-10',
      renewalDate: '2026-12-01',
    );
    final retainer = buildTestProject(
      type: ProjectType.retainer,
      endDate: '2026-11-10',
      renewalDate: '2026-12-01',
    );
    expect(projectDueDate(oneTime), DateTime(2026, 11, 10));
    expect(projectDueDate(retainer), DateTime(2026, 12, 1));
  });

  test('near deadline covers today through the next 14 days', () {
    bool near(String? end) => matchesDueFilter(
      buildTestProject(endDate: end),
      ProjectDueFilter.dueSoon,
      today,
    );
    expect(near('2026-11-03'), isTrue);
    expect(near('2026-11-17'), isTrue);
    expect(near('2026-11-18'), isFalse);
    expect(near('2026-11-02'), isFalse);
    expect(near(null), isFalse);
  });

  test('deadline passed only counts projects that are still open', () {
    bool passed(String status) => matchesDueFilter(
      buildTestProject(status: status, endDate: '2026-10-01'),
      ProjectDueFilter.overdue,
      today,
    );
    expect(passed(ProjectStatus.active), isTrue);
    expect(passed(ProjectStatus.onHold), isTrue);
    expect(passed(ProjectStatus.completed), isFalse);
    expect(passed(ProjectStatus.cancelled), isFalse);
  });

  test('no date set finds open projects missing their date', () {
    expect(
      matchesDueFilter(buildTestProject(), ProjectDueFilter.noDate, today),
      isTrue,
    );
    expect(
      matchesDueFilter(
        buildTestProject(status: ProjectStatus.completed),
        ProjectDueFilter.noDate,
        today,
      ),
      isFalse,
    );
  });
}
