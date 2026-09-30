/// Triggers a browser download of [bytes] as [filename] (e.g. a
/// server-generated PDF). Web-only today — this app is deployed as a
/// Flutter web build in practice (see CLAUDE.md's deployment notes), and no
/// other platform target has exercised this flow yet. The stub
/// implementation throws so a future native build fails loudly instead of
/// silently doing nothing.
library;

export 'file_download_stub.dart'
    if (dart.library.js_interop) 'file_download_web.dart';
