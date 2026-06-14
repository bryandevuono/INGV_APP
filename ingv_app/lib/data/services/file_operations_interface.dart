import 'package:ingv_app/data/models/event_attachment.dart';
import 'package:ingv_app/data/models/file_version.dart';

abstract class ILocalFileService {
  Future<String?> resolvePath(EventAttachment attachment);

  Future<String?> saveAttachmentCopy(EventAttachment attachment);
}

abstract class IFileOpenService {
  Future<bool> openFile(String filePath);
}
