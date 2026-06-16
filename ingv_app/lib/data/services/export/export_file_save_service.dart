import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

abstract class IExportFileSaveService {
  Future<String> savePdf(Uint8List bytes, String fileName);

  Future<String> saveZip(Uint8List bytes, String fileName);
}

class FileSaverExportFileSaveService implements IExportFileSaveService {
  @override
  Future<String> savePdf(Uint8List bytes, String fileName) async {
    final savePath = await FilePicker.saveFile(
      dialogTitle: 'Save PDF export',
      fileName: '$fileName.pdf',
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      bytes: bytes,
    );

    return savePath ?? '';
  }

  @override
  Future<String> saveZip(Uint8List bytes, String fileName) async {
    final savePath = await FilePicker.saveFile(
      dialogTitle: 'Save ZIP export',
      fileName: '$fileName.zip',
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      bytes: bytes,
    );

    return savePath ?? '';
  }
}
