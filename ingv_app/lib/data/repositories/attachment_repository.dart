import 'package:ingv_app/data/models/event_attachment.dart';
import 'package:ingv_app/data/models/file_version.dart';
import '../services/attachment_service.dart';

class AttachmentRepository {
  final AttachmentService _attachmentService;

  AttachmentRepository(this._attachmentService);

  Future<List<EventAttachment>> getAttachmentsForEvent(String eventId) async {
    return _attachmentService.getAttachmentsForEvent(eventId);
  }

  Future<EventAttachment?> getAttachmentById(String attachmentId) async {
    return _attachmentService.getAttachmentById(attachmentId);
  }

  Future<void> addAttachment(EventAttachment attachment) async {
    await _attachmentService.addAttachment(attachment);
  }

  Future<void> deleteAttachment(String attachmentId) async {
    await _attachmentService.deleteAttachment(attachmentId);
  }

  Future<void> updateAttachment(EventAttachment attachment) async {
    await _attachmentService.updateAttachment(attachment);
  }

  Future<List<FileVersion>> getFileHistoryFromAttachment(String attachmentId) async {
    return _attachmentService.getFileHistory(attachmentId);
  }

  Future<void> saveMergedVersion(String attachmentId, String mergedContent) async {
    await _attachmentService.createMergedVersion(
      attachmentId: attachmentId,
      mergedContent: mergedContent,
    );
  }

  Future<void> addNewAttachmentVersion(EventAttachment attachment) async {
    await _attachmentService.createNewAttachmentVersion(attachment);
    await _attachmentService.updateAttachment(attachment);
  }
}