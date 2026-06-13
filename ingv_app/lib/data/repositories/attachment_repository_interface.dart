import '../models/event_attachment.dart';
import '../models/file_version.dart';

abstract class IAttachmentRepository {
  Future<List<EventAttachment>> getAttachmentsForEvent(String eventId);

  Future<EventAttachment?> getAttachmentById(String attachmentId);

  Future<void> addAttachment(EventAttachment attachment);

  Future<void> deleteAttachment(String attachmentId);

  Future<void> updateAttachment(EventAttachment attachment);

  Future<List<FileVersion>> getFileHistoryFromAttachment();

}
