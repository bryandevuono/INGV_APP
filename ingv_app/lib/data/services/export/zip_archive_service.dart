import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'export_result.dart';

abstract class IZipArchiveService {
  Uint8List createZip(List<ExportArchiveEntry> entries);
}

class ArchiveZipArchiveService implements IZipArchiveService {
  @override
  Uint8List createZip(List<ExportArchiveEntry> entries) {
    final archive = Archive();
    for (final entry in entries) {
      archive.addFile(ArchiveFile(entry.path, entry.bytes.length, entry.bytes));
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }
}
