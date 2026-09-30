void downloadBytes(
  List<int> bytes,
  String filename, {
  String mimeType = 'application/pdf',
}) {
  throw UnsupportedError(
    'File download is only implemented for the web build.',
  );
}
