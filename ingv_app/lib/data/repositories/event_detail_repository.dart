import '../models/event_note_model.dart';
import '../models/event_media_model.dart';
import '../models/event_attachment_model.dart';
import '../services/event_detail_service_interface.dart';

abstract interface class IEventDetailRepository {
  Future<List<EventNoteModel>> getNotesByEventId(int eventId);
  Future<List<EventMediaModel>> getMediaByEventId(int eventId);
  Future<List<EventAttachmentModel>> getAttachmentsByEventId(int eventId);
  Future<void> addNote(int eventId, EventNoteModel note);
  Future<void> deleteNote(int noteId);
  Future<void> addMedia(int eventId, EventMediaModel media);
  Future<void> addAttachment(int eventId, EventAttachmentModel attachment);
}

class EventDetailRepository implements IEventDetailRepository {
  final IEventDetailService _detailService;

  EventDetailRepository(this._detailService);

  @override
  Future<List<EventNoteModel>> getNotesByEventId(int eventId) {
    return _detailService.getNotesByEventId(eventId);
  }

  @override
  Future<List<EventMediaModel>> getMediaByEventId(int eventId) {
    return _detailService.getMediaByEventId(eventId);
  }

  @override
  Future<List<EventAttachmentModel>> getAttachmentsByEventId(int eventId) {
    return _detailService.getAttachmentsByEventId(eventId);
  }

  @override
  Future<void> addNote(int eventId, EventNoteModel note) {
    return _detailService.addNote(eventId, note);
  }

  @override
  Future<void> deleteNote(int noteId) {
    return _detailService.deleteNote(noteId);
  }

  @override
  Future<void> addMedia(int eventId, EventMediaModel media) {
    return _detailService.addMedia(eventId, media);
  }

  @override
  Future<void> addAttachment(int eventId, EventAttachmentModel attachment) {
    return _detailService.addAttachment(eventId, attachment);
  }
}
