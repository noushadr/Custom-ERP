import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/employee_document.dart';
import 'package:zera_erp/features/employee/presentation/widgets/employee_documents_section.dart';

import '../../../helpers/fake_employee.dart';

Widget _app({required List<EmployeeDocument> documents}) {
  return ProviderScope(
    overrides: [
      employeeRepositoryProvider.overrideWithValue(
        FakeEmployeeRepository(documents: documents),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: EmployeeDocumentsSection())),
  );
}

void main() {
  testWidgets('shows an inline thumbnail for an image CNIC upload', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        documents: [
          EmployeeDocument(
            id: 'doc-1',
            documentType: DocumentType.cnic,
            fileName: 'cnic-front.jpg',
            fileSize: 204800,
            url: 'https://example.com/uploads/cnic-front.jpg',
            uploadedAt: DateTime(2026, 1, 1),
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('shows no thumbnail for a non-image document', (tester) async {
    await tester.pumpWidget(
      _app(
        documents: [
          EmployeeDocument(
            id: 'doc-1',
            documentType: DocumentType.contract,
            fileName: 'contract.pdf',
            fileSize: 204800,
            url: 'https://example.com/uploads/contract.pdf',
            uploadedAt: DateTime(2026, 1, 1),
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsNothing);
    expect(find.textContaining('contract.pdf'), findsOneWidget);
  });
}
