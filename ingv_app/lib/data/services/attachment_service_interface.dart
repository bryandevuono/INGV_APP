import 'package:ingv_app/data/models/event_attachment.dart';
import 'package:ingv_app/data/models/file_version.dart';

abstract class IAttachmentService {
  List<FileVersion> getFileHistoryFromAttachment(Map<String, List<FileVersion>> registry, String attachmentId);
  
  void createMergedVersion({
    required String attachmentId,
    required String mergedContent,
  });

  void createNewAttachmentVersion(EventAttachment attachment);
}