import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations, QuillEditor;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/application/role_providers.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/knowledge_base/application/knowledge_base_file_support.dart';
import 'package:zera_erp/features/knowledge_base/application/knowledge_base_providers.dart';
import 'package:zera_erp/features/knowledge_base/domain/exceptions/knowledge_base_exception.dart';
import 'package:zera_erp/features/knowledge_base/presentation/pages/knowledge_base_article_page.dart';
import 'package:zera_erp/features/knowledge_base/presentation/pages/knowledge_base_editor_page.dart';
import 'package:zera_erp/features/knowledge_base/presentation/pages/knowledge_base_page.dart';
import 'package:zera_erp/features/knowledge_base/presentation/pages/knowledge_base_version_page.dart';
import 'package:zera_erp/features/knowledge_base/presentation/widgets/knowledge_base_content_view.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_knowledge_base.dart';

/// Records what the viewer did with a fetched file (the real implementations
/// throw outside a browser).
class _FileActionsRecorder {
  final downloads = <({String fileName, String mimeType, int length})>[];
  final opens = <({String mimeType, int length})>[];

  /// What `open` reports — false simulates a blocked pop-up.
  bool openSucceeds = true;

  KnowledgeBaseFileActions get actions => KnowledgeBaseFileActions(
    download: (bytes, fileName, mimeType) => downloads.add((
      fileName: fileName,
      mimeType: mimeType,
      length: bytes.length,
    )),
    open: (bytes, mimeType) {
      opens.add((mimeType: mimeType, length: bytes.length));
      return openSucceeds;
    },
  );
}

Future<void> _useTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app({
  required Widget home,
  required FakeKnowledgeBaseRepository repository,
  _FileActionsRecorder? recorder,
  PickedKnowledgeBaseFile? pickedFile,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(const AuthAuthenticated(testAuthUser)),
      ),
      knowledgeBaseRepositoryProvider.overrideWithValue(repository),
      knowledgeBaseFileActionsProvider.overrideWithValue(
        (recorder ?? _FileActionsRecorder()).actions,
      ),
      knowledgeBaseFilePickerProvider.overrideWithValue(() async => pickedFile),
      rolesProvider.overrideWith((ref) async => const []),
      departmentsProvider.overrideWith((ref) async => const []),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: home,
    ),
  );
}

PickedKnowledgeBaseFile _pdf([String name = 'Policy.pdf']) =>
    PickedKnowledgeBaseFile(
      fileName: name,
      bytes: Uint8List.fromList(List.filled(1536, 7)),
    );

void main() {
  group('reading a file article', () {
    testWidgets('shows the file card instead of written content', (
      tester,
    ) async {
      final repository = FakeKnowledgeBaseRepository(
        articleById: buildTestKnowledgeBaseFileArticle(),
      );

      await tester.pumpWidget(
        _app(
          home: const KnowledgeBaseArticlePage(articleId: 'article-1'),
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Leave Policy'), findsOneWidget);
      expect(find.text('Leave Policy.pdf'), findsOneWidget);
      expect(find.text('2.0 KB'), findsOneWidget);
      expect(find.byType(KnowledgeBaseContentView), findsNothing);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('Download fetches the file through the API and saves it', (
      tester,
    ) async {
      final repository = FakeKnowledgeBaseRepository(
        articleById: buildTestKnowledgeBaseFileArticle(),
      );
      final recorder = _FileActionsRecorder();

      await tester.pumpWidget(
        _app(
          home: const KnowledgeBaseArticlePage(articleId: 'article-1'),
          repository: repository,
          recorder: recorder,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();

      expect(repository.lastDownloadedArticleId, 'article-1');
      expect(recorder.downloads, hasLength(1));
      expect(recorder.downloads.single.fileName, 'Leave Policy.pdf');
      expect(recorder.downloads.single.mimeType, 'application/pdf');
      expect(recorder.downloads.single.length, 3);
      expect(recorder.opens, isEmpty);
    });

    testWidgets('Open shows a PDF in a new tab without downloading it', (
      tester,
    ) async {
      final repository = FakeKnowledgeBaseRepository(
        articleById: buildTestKnowledgeBaseFileArticle(),
      );
      final recorder = _FileActionsRecorder();

      await tester.pumpWidget(
        _app(
          home: const KnowledgeBaseArticlePage(articleId: 'article-1'),
          repository: repository,
          recorder: recorder,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(recorder.opens, hasLength(1));
      expect(recorder.opens.single.mimeType, 'application/pdf');
      expect(recorder.downloads, isEmpty);
    });

    testWidgets('a blocked pop-up falls back to a download', (tester) async {
      final repository = FakeKnowledgeBaseRepository(
        articleById: buildTestKnowledgeBaseFileArticle(),
      );
      final recorder = _FileActionsRecorder()..openSucceeds = false;

      await tester.pumpWidget(
        _app(
          home: const KnowledgeBaseArticlePage(articleId: 'article-1'),
          repository: repository,
          recorder: recorder,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(recorder.opens, hasLength(1));
      expect(recorder.downloads, hasLength(1));
    });

    testWidgets('a Word document is download-only (no Open button)', (
      tester,
    ) async {
      final repository = FakeKnowledgeBaseRepository(
        articleById: buildTestKnowledgeBaseFileArticle(
          fileName: 'Handbook.docx',
          fileMimeType:
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        ),
      );

      await tester.pumpWidget(
        _app(
          home: const KnowledgeBaseArticlePage(articleId: 'article-1'),
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Handbook.docx'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Open'), findsNothing);
    });

    testWidgets('a failed download shows the reason and saves nothing', (
      tester,
    ) async {
      final repository = FakeKnowledgeBaseRepository(
        articleById: buildTestKnowledgeBaseFileArticle(),
        downloadError: const KnowledgeBaseException(
          "You don't have permission to do that.",
        ),
      );
      final recorder = _FileActionsRecorder();

      await tester.pumpWidget(
        _app(
          home: const KnowledgeBaseArticlePage(articleId: 'article-1'),
          repository: repository,
          recorder: recorder,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();

      expect(
        find.text("You don't have permission to do that."),
        findsOneWidget,
      );
      expect(recorder.downloads, isEmpty);
    });
  });

  group('version history', () {
    testWidgets("a past version's file is downloaded from that version", (
      tester,
    ) async {
      final repository = FakeKnowledgeBaseRepository(
        versionById: buildTestKnowledgeBaseArticleVersion(
          id: 'version-1',
          fileName: 'Old Policy.pdf',
          fileMimeType: 'application/pdf',
          fileSizeBytes: 1024,
        ),
      );
      final recorder = _FileActionsRecorder();

      await tester.pumpWidget(
        _app(
          home: const KnowledgeBaseVersionPage(
            articleId: 'article-1',
            versionId: 'version-1',
          ),
          repository: repository,
          recorder: recorder,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Old Policy.pdf'), findsOneWidget);
      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();

      expect(repository.lastDownloadedVersionArticleId, 'article-1');
      expect(repository.lastDownloadedVersionId, 'version-1');
      expect(recorder.downloads.single.fileName, 'Old Policy.pdf');
    });

    testWidgets('a written version still shows its text, not a file card', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          home: const KnowledgeBaseVersionPage(
            articleId: 'article-1',
            versionId: 'version-1',
          ),
          repository: FakeKnowledgeBaseRepository(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(KnowledgeBaseContentView), findsOneWidget);
      expect(find.text('Download'), findsNothing);
    });
  });

  group('the article list', () {
    testWidgets('marks uploaded-file articles with a paperclip', (
      tester,
    ) async {
      final repository = FakeKnowledgeBaseRepository(
        articles: [
          buildTestKnowledgeBaseArticleSummary(
            id: 'a-written',
            title: 'Written Guide',
          ),
          buildTestKnowledgeBaseArticleSummary(
            id: 'a-file',
            title: 'Policy PDF',
            contentKind: 'file',
            fileName: 'Policy.pdf',
            fileMimeType: 'application/pdf',
            fileSizeBytes: 100,
          ),
        ],
      );

      await tester.pumpWidget(
        _app(home: const KnowledgeBasePage(), repository: repository),
      );
      await tester.pumpAndSettle();

      expect(find.text('Written Guide'), findsOneWidget);
      expect(find.text('Policy PDF'), findsOneWidget);
      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });
  });

  group('the editor', () {
    testWidgets('Upload file swaps the text editor for a file chooser', (
      tester,
    ) async {
      await _useTallSurface(tester);
      await tester.pumpWidget(
        _app(
          home: const KnowledgeBaseEditorPage(),
          repository: FakeKnowledgeBaseRepository(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(QuillEditor), findsOneWidget);
      expect(find.text('Choose file'), findsNothing);

      await tester.tap(find.text('Upload file'));
      await tester.pumpAndSettle();

      expect(find.byType(QuillEditor), findsNothing);
      expect(find.text('Choose file'), findsOneWidget);
    });

    testWidgets('publishing an upload with no file chosen is refused', (
      tester,
    ) async {
      await _useTallSurface(tester);
      final repository = FakeKnowledgeBaseRepository();
      await tester.pumpWidget(
        _app(home: const KnowledgeBaseEditorPage(), repository: repository),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Upload file'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Leave Policy');
      await tester.tap(find.text('Publish'));
      await tester.pumpAndSettle();

      expect(find.text('Choose a file to upload.'), findsOneWidget);
      expect(repository.lastFileCreatedTitle, isNull);
    });

    testWidgets('a chosen file is shown, then uploaded on publish', (
      tester,
    ) async {
      await _useTallSurface(tester);
      final repository = FakeKnowledgeBaseRepository();
      await tester.pumpWidget(
        _app(
          home: const KnowledgeBaseEditorPage(),
          repository: repository,
          pickedFile: _pdf('Policy.pdf'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Upload file'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Leave Policy');
      await tester.tap(find.text('Choose file'));
      await tester.pumpAndSettle();

      expect(find.text('Policy.pdf (1.5 KB)'), findsOneWidget);
      expect(find.text('Choose a different file'), findsOneWidget);

      await tester.tap(find.text('Publish'));
      await tester.pumpAndSettle();

      expect(repository.lastFileCreatedTitle, 'Leave Policy');
      expect(repository.lastFileCreatedFileName, 'Policy.pdf');
      expect(repository.lastFileCreatedBytes, hasLength(1536));
      expect(repository.lastFileCreatedVisibilityType, 'everyone');
      // The written-article endpoint is never touched for an upload.
      expect(repository.lastCreatedTitle, isNull);
    });

    testWidgets('a written article has no write/upload switch when editing', (
      tester,
    ) async {
      await _useTallSurface(tester);
      await tester.pumpWidget(
        _app(
          home: KnowledgeBaseEditorPage(
            existingArticle: buildTestKnowledgeBaseArticle(),
          ),
          repository: FakeKnowledgeBaseRepository(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upload file'), findsNothing);
      expect(find.byType(QuillEditor), findsOneWidget);
    });

    testWidgets(
      'editing a file article shows its current file and saves a title change '
      'without uploading anything',
      (tester) async {
        await _useTallSurface(tester);
        final repository = FakeKnowledgeBaseRepository();
        await tester.pumpWidget(
          _app(
            home: KnowledgeBaseEditorPage(
              existingArticle: buildTestKnowledgeBaseFileArticle(),
            ),
            repository: repository,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(QuillEditor), findsNothing);
        expect(find.text('Leave Policy.pdf'), findsOneWidget);
        expect(find.text('Replace file'), findsOneWidget);

        await tester.enterText(
          find.byType(TextFormField).first,
          'Leave Policy 2026',
        );
        await tester.tap(find.text('Save changes'));
        await tester.pumpAndSettle();

        expect(repository.lastUpdatedId, 'article-1');
        expect(repository.lastUpdatedTitle, 'Leave Policy 2026');
        // No written content is sent for a file article.
        expect(repository.lastUpdatedContent, isNull);
        expect(repository.lastReplacedId, isNull);
      },
    );

    testWidgets(
      'replacing the file uploads it, then updates visibility separately '
      '(so only one new version is recorded)',
      (tester) async {
        await _useTallSurface(tester);
        final repository = FakeKnowledgeBaseRepository();
        await tester.pumpWidget(
          _app(
            home: KnowledgeBaseEditorPage(
              existingArticle: buildTestKnowledgeBaseFileArticle(),
            ),
            repository: repository,
            pickedFile: _pdf('Leave Policy v2.pdf'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Replace file'));
        await tester.pumpAndSettle();
        expect(find.text('Leave Policy v2.pdf (1.5 KB)'), findsOneWidget);

        await tester.tap(find.text('Save changes'));
        await tester.pumpAndSettle();

        expect(repository.lastReplacedId, 'article-1');
        expect(repository.lastReplacedFileName, 'Leave Policy v2.pdf');
        expect(repository.lastReplacedTitle, 'Leave Policy');
        // The follow-up update carries targeting only - no title, so the
        // backend doesn't record a second version.
        expect(repository.lastUpdatedId, 'article-1');
        expect(repository.lastUpdatedTitle, isNull);
        expect(repository.lastUpdatedVisibilityType, 'everyone');
      },
    );
  });
}
