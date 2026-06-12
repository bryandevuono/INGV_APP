import 'dart:typed_data';

class ExportResult {
  final String fileName;
  final String saveLocation;
  final Uint8List bytes;

  const ExportResult({
    required this.fileName,
    required this.saveLocation,
    required this.bytes,
  });
}

class ExportArchiveEntry {
  final String path;
  final List<int> bytes;

  const ExportArchiveEntry({required this.path, required this.bytes});
}
