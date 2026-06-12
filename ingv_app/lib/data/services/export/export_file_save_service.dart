import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

abstract class IExportFileSaveService {
  Future<String> savePdf(Uint8List bytes, String fileName);

  Future<String> saveZip(Uint8List bytes, String fileName);
}

class FileSaverExportFileSaveService implements IExportFileSaveService {
  @override
  Future<String> savePdf(Uint8List bytes, String fileName) {
    return FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  @override
  Future<String> saveZip(Uint8List bytes, String fileName) {
    return FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      fileExtension: 'zip',
      mimeType: MimeType.other,
    );
  }
}
