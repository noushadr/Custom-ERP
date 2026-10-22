import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

void downloadBytes(
  List<int> bytes,
  String filename, {
  String mimeType = 'application/pdf',
}) {
  final blobParts = <JSUint8Array>[Uint8List.fromList(bytes).toJS].toJS;
  final blob = web.Blob(blobParts, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

/// Opens [bytes] in a new browser tab (for types the browser can display
/// itself, such as PDFs and images). Returns false when the browser blocked
/// the pop-up, so the caller can fall back to a download. The object URL is
/// kept alive for a minute so the new tab has time to load it.
bool openBytesInNewTab(List<int> bytes, {required String mimeType}) {
  final blobParts = <JSUint8Array>[Uint8List.fromList(bytes).toJS].toJS;
  final blob = web.Blob(blobParts, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final opened = web.window.open(url, '_blank');
  Future<void>.delayed(
    const Duration(minutes: 1),
    () => web.URL.revokeObjectURL(url),
  );
  return opened != null;
}
