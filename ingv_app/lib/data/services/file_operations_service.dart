import 'dart:io';
import 'package:flutter/services.dart';
import 'package:ingv_app/data/models/event_attachment.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'file_operations_interface.dart';

class LocalFileService implements ILocalFileService {
  Future<Directory> _ensureDirectory(String name) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final directory = Directory('${documentsDir.path}/$name');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  @override
  Future<String?> resolvePath(EventAttachment attachment) async {
    try {
      if (attachment.localPath != null && attachment.localPath!.isNotEmpty) {
        final localFile = File(attachment.localPath!);
        if (await localFile.exists()) {
          return localFile.path;
        }
      }

      if (attachment.assetPath != null && attachment.assetPath!.isNotEmpty) {
        final assetData = await rootBundle.load(attachment.assetPath!);
        final cacheDir = await _ensureDirectory('attachment_cache');
        final filePath = '${cacheDir.path}/${attachment.fileName}';
        final file = File(filePath);
        await file.writeAsBytes(assetData.buffer.asUint8List(), flush: true);
        return file.path;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> saveAttachmentCopy(EventAttachment attachment) async {
    try {
      final sourcePath = await resolvePath(attachment);
      if (sourcePath == null) {
        return null;
      }

      final savedDir = await _ensureDirectory('saved_attachments');
      final destinationPath = '${savedDir.path}/${attachment.fileName}';
      final sourceFile = File(sourcePath);
      await sourceFile.copy(destinationPath);
      return destinationPath;
    } catch (e) {
      return null;
    }
  }
}

class FileOpenService implements IFileOpenService {
  @override
  Future<bool> openFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      return false;
    }
  }
}
