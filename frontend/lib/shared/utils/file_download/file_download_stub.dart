void downloadBytes(
  List<int> bytes,
  String filename, {
  String mimeType = 'application/pdf',
}) {
  throw UnsupportedError(
    'File download is only implemented for the web build.',
  );
}

bool openBytesInNewTab(List<int> bytes, {required String mimeType}) {
  throw UnsupportedError(
    'Opening a file is only implemented for the web build.',
  );
}
