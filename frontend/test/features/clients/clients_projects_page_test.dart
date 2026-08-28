import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/clients/application/clients_providers.dart';
import 'package:zera_erp/features/clients/domain/entities/client_health_status.dart';
import 'package:zera_erp/features/clients/domain/entities/project_refs.dart';
import 'package:zera_erp/features/clients/domain/entities/project_status.dart';
import 'package:zera_erp/features/clients/domain/entities/project_type.dart';
import 'package:zera_erp/features/clients/presentation/pages/clients_projects_page.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/shared/widgets/form_section.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_clients.dart';
import '../../helpers/fake_employee.dart';

/// Scopes a text lookup to inside the named `TopBreakdownPanel` (a titled
/// `FormSection`) — needed now that the Projects/Clients tables also show
/// countries/services/lead sources as plain columns, so a bare
/// `find.text(...)` can match both the panel's bar-row label and a table
/// cell.
Finder _inPanel(String panelTitle, String text) => find.descendant(
  of: find.widgetWithText(FormSection, panelTitle),
  matching: find.text(text),
);

const _superAdmin = AuthUser(
  id: 'admin-1',
  email: 'admin@zeracreative.com',
  role: 'Super Admin',
  permissions: ['clients.manage'],
);

/// The tab bar (Projects/Clients/Health) sits next to the New Client/New
/// Project buttons in one row — on the default 800x600 test surface that
/// combination doesn't fit and the last tab overlaps the buttons instead of
/// scrolling, so tests that need to reach the Health tab use a wider one.
Future<void> _useWideSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app({FakeClientsRepository? repository, AuthUser? viewer}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(viewer ?? _superAdmin)),
      ),
      employeeRepositoryProvider.overrideWithValue(FakeEmployeeRepository()),
      clientsRepositoryProvider.overrideWithValue(
        repository ?? FakeClientsRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: ClientsProjectsPage())),
  );
}

void main() {
  testWidgets('renders the summary stat tiles', (tester) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          clients: [
            buildTestClient(id: 'c1', companyName: 'Acme Co'),
            buildTestClient(id: 'c2', companyName: 'Beta LLC'),
          ],
          projects: [
            buildTestProject(
              id: 'p1',
              clientId: 'c1',
              clientName: 'Acme Co',
              type: ProjectType.retainer,
              status: ProjectStatus.active,
            ),
            buildTestProject(
              id: 'p2',
              clientId: 'c2',
              clientName: 'Beta LLC',
              type: ProjectType.oneTime,
              status: ProjectStatus.completed,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total Clients'), findsOneWidget);
    expect(find.text('Active Clients'), findsOneWidget);
    expect(find.text('Monthly Retainers'), findsOneWidget);
    expect(find.text('One-Time Projects'), findsOneWidget);
    // Total Clients: 2, Active Clients: 1 (only Acme Co has an active
    // project), Monthly Retainers: 1, One-Time Projects: 1.
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(3));
  });

  testWidgets(
    'shows Top Countries, Top Services, and Top Lead Sources breakdown '
    'panels — countries render as short codes, services are pulled from '
    'each project\'s assigned services',
    (tester) async {
      await tester.pumpWidget(
        _app(
          repository: FakeClientsRepository(
            clients: [
              buildTestClient(
                id: 'c1',
                companyName: 'Acme Co',
                country: 'Pakistan',
                leadSource: 'Whatsapp',
              ),
              buildTestClient(
                id: 'c2',
                companyName: 'Beta LLC',
                country: 'saudia',
                leadSource: 'Referral',
              ),
              buildTestClient(
                id: 'c3',
                companyName: 'Gamma Inc',
                country: 'Pakistan',
                leadSource: 'Whatsapp',
              ),
            ],
            projects: [
              buildTestProject(
                id: 'p1',
                clientId: 'c1',
                clientName: 'Acme Co',
                services: const [ProjectServiceRef(id: 's1', name: 'SEO')],
              ),
              buildTestProject(
                id: 'p2',
                clientId: 'c2',
                clientName: 'Beta LLC',
                services: const [ProjectServiceRef(id: 's2', name: 'SMM')],
              ),
              buildTestProject(
                id: 'p3',
                clientId: 'c3',
                clientName: 'Gamma Inc',
                services: const [ProjectServiceRef(id: 's1', name: 'SEO')],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Top Countries'), findsOneWidget);
      expect(find.text('Top Services'), findsOneWidget);
      expect(find.text('Top Lead Sources'), findsOneWidget);

      // Scoped to each panel specifically — the Projects/Clients tables
      // below now also show countries/services/lead sources as plain
      // columns, so these values legitimately appear more than once on
      // screen.
      // 2 clients are in Pakistan (flag + short code), 1 in Saudi Arabia.
      expect(_inPanel('Top Countries', '🇵🇰 PK'), findsOneWidget);
      expect(_inPanel('Top Countries', '🇸🇦 KSA'), findsOneWidget);
      // 2 projects use SEO, 1 uses SMM.
      expect(_inPanel('Top Services', 'SEO'), findsOneWidget);
      expect(_inPanel('Top Services', 'SMM'), findsOneWidget);
      // 2 clients came via Whatsapp, 1 via Referral.
      expect(_inPanel('Top Lead Sources', 'Whatsapp'), findsOneWidget);
      expect(_inPanel('Top Lead Sources', 'Referral'), findsOneWidget);
    },
  );

  testWidgets(
    'the Projects tab renders as a detailed table — type, status, start '
    'date, package, employees, and services all visible per row',
    (tester) async {
      await tester.pumpWidget(
        _app(
          repository: FakeClientsRepository(
            projects: [
              buildTestProject(
                clientName: 'Acme Co',
                name: 'SEO Retainer',
                type: ProjectType.retainer,
                status: ProjectStatus.active,
                startDate: '2026-02-15',
                packageName: 'GROWTH +',
                assignedEmployees: const [
                  ProjectEmployeeRef(
                    id: 'e1',
                    fullName: 'Jane Employee',
                    photoUrl: null,
                  ),
                ],
                services: const [ProjectServiceRef(id: 's1', name: 'SEO')],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Acme Co'), findsOneWidget);
      expect(find.text('SEO Retainer'), findsOneWidget);
      expect(find.text('Retainer'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('2026-02-15'), findsOneWidget);
      expect(find.text('GROWTH +'), findsOneWidget);
      expect(find.text('Jane Employee'), findsOneWidget);
      // At least once — the "Top Services" breakdown panel above the
      // table also derives from this same project's services, so "SEO"
      // legitimately appears twice on screen.
      expect(find.text('SEO'), findsWidgets);
    },
  );

  testWidgets(
    'a project with no package/employees/services shows an em dash for '
    'each',
    (tester) async {
      await tester.pumpWidget(
        _app(
          repository: FakeClientsRepository(
            projects: [buildTestProject(name: 'Bare Project')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bare Project'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(3));
    },
  );

  testWidgets(
    'the Clients tab renders as a detailed table — contact, email, phone, '
    'country, industry, and lead source all visible per row',
    (tester) async {
      await tester.pumpWidget(
        _app(
          repository: FakeClientsRepository(
            clients: [
              buildTestClient(
                companyName: 'Acme Co',
                industry: 'E-commerce',
                country: 'Pakistan',
                primaryContactName: 'Jane Client',
                primaryContactEmail: 'jane@acme.test',
                primaryContactPhone: '+92 300 1234567',
                leadSource: 'Referral',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clients'));
      await tester.pumpAndSettle();

      expect(find.text('Acme Co'), findsOneWidget);
      expect(find.text('Jane Client'), findsOneWidget);
      expect(find.text('jane@acme.test'), findsOneWidget);
      expect(find.text('+92 300 1234567'), findsOneWidget);
      // At least once — the "Top Countries" breakdown panel above the
      // table also derives from this same client's country, so the flag
      // code legitimately appears twice on screen.
      expect(find.text('🇵🇰 PK'), findsWidgets);
      expect(find.text('E-commerce'), findsOneWidget);
      // Also mirrored in the "Top Lead Sources" breakdown panel above.
      expect(find.text('Referral'), findsWidgets);
    },
  );

  testWidgets('shows the Projects tab by default with New Project/New Client buttons', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          projects: [buildTestProject(name: 'Website Revamp')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Website Revamp'), findsOneWidget);
    expect(find.text('New Project'), findsOneWidget);
    expect(find.text('New Client'), findsOneWidget);
  });

  testWidgets('switching to the Clients tab shows clients instead of projects', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          projects: [
            buildTestProject(name: 'Website Revamp', clientName: 'Acme Co'),
          ],
          clients: [buildTestClient(companyName: 'Beta LLC')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Website Revamp'), findsOneWidget);
    expect(find.text('Beta LLC'), findsNothing);

    await tester.tap(find.text('Clients'));
    await tester.pumpAndSettle();

    expect(find.text('Beta LLC'), findsOneWidget);
    expect(find.text('Website Revamp'), findsNothing);
  });

  testWidgets('shows an empty state when there are no projects', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('No projects yet.'), findsOneWidget);
  });

  testWidgets('shows a health badge on each row in the Clients tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          clients: [
            buildTestClient(
              companyName: 'Acme Co',
              healthStatus: ClientHealthStatus.atRisk,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clients'));
    await tester.pumpAndSettle();

    expect(find.text('At Risk'), findsOneWidget);
  });

  testWidgets('the Health tab shows counts and a worst-first at-risk list', (
    tester,
  ) async {
    await _useWideSurface(tester);
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          clients: [
            buildTestClient(
              id: 'c1',
              companyName: 'Healthy Co',
              healthStatus: ClientHealthStatus.healthy,
            ),
            buildTestClient(
              id: 'c2',
              companyName: 'Attention Co',
              healthStatus: ClientHealthStatus.attentionRequired,
            ),
            buildTestClient(
              id: 'c3',
              companyName: 'Risky Co',
              healthStatus: ClientHealthStatus.atRisk,
            ),
          ],
          clientHealthSummary: buildTestClientHealthSummary(
            healthyCount: 1,
            attentionRequiredCount: 1,
            atRiskCount: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Health'));
    await tester.pumpAndSettle();

    // "Attention Required"/"At Risk" each appear twice: once as a stat tile
    // label, once as the health badge on the matching client's row.
    expect(find.text('Healthy'), findsOneWidget);
    expect(find.text('Attention Required'), findsNWidgets(2));
    expect(find.text('At Risk'), findsNWidgets(2));
    expect(find.text('Healthy Co'), findsNothing);
    expect(find.text('Attention Co'), findsOneWidget);
    expect(find.text('Risky Co'), findsOneWidget);

    // Worst-first: "Risky Co" (At Risk) must appear above "Attention Co".
    final riskyPosition = tester.getTopLeft(find.text('Risky Co')).dy;
    final attentionPosition = tester.getTopLeft(find.text('Attention Co')).dy;
    expect(riskyPosition, lessThan(attentionPosition));
  });

  testWidgets('the Health tab shows an empty state when nothing needs attention', (
    tester,
  ) async {
    await _useWideSurface(tester);
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          clients: [
            buildTestClient(
              companyName: 'Healthy Co',
              healthStatus: ClientHealthStatus.healthy,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Health'));
    await tester.pumpAndSettle();

    expect(find.text('No clients need attention right now.'), findsOneWidget);
  });

  testWidgets(
    'shows an access-denied message instead of any client/project data for '
    'a viewer without clients.manage — a frontend-side second line of '
    'defense on top of the backend already rejecting the request, since '
    "this app's IndexedStack-based nav keeps every page mounted regardless "
    'of which tab is visible',
    (tester) async {
      final repository = FakeClientsRepository(
        clients: [buildTestClient(companyName: 'Should Not Be Visible')],
      );

      await tester.pumpWidget(
        _app(
          repository: repository,
          viewer: const AuthUser(
            id: 'employee-1',
            email: 'employee@zeracreative.com',
            role: 'Employee',
            permissions: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text("You don't have permission to view this page."),
        findsOneWidget,
      );
      expect(find.text('Should Not Be Visible'), findsNothing);
      expect(find.text('Projects'), findsNothing);
      expect(repository.getClientsCallCount, 0);
    },
  );
}
