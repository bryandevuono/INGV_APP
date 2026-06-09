import '../models/event_attachment.dart';

abstract class IAttachmentRepository {
  Future<List<EventAttachment>> getAttachmentsForEvent(String eventId);

  Future<EventAttachment?> getAttachmentById(String attachmentId);

  Future<void> addAttachment(EventAttachment attachment);

  Future<void> deleteAttachment(String attachmentId);

  Future<void> updateAttachment(EventAttachment attachment);
}
