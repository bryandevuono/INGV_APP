import '../models/event_attachment.dart';

abstract class IAttachmentRepository {
  /// Get all local attachments for a specific event
  Future<List<EventAttachment>> getAttachmentsForEvent(String eventId);

  /// Get a specific local attachment by ID
  Future<EventAttachment?> getAttachmentById(String attachmentId);

  /// Add a new local attachment to an event
  Future<void> addAttachment(EventAttachment attachment);

  /// Delete an attachment
  Future<void> deleteAttachment(String attachmentId);

  /// Update attachment metadata
  Future<void> updateAttachment(EventAttachment attachment);
}
