import 'package:ingv_app/data/models/event_attachment.dart';

abstract class ILocalFileService {
  /// Resolve a local path that can be opened or previewed.
  Future<String?> resolvePath(EventAttachment attachment);

  /// Save a copy of the attachment into an application-managed local folder.
  Future<String?> saveAttachmentCopy(EventAttachment attachment);
}

abstract class IFileOpenService {
  /// Open a local file with the default application
  Future<bool> openFile(String filePath);
}
