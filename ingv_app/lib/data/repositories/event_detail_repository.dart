import '../models/event_model.dart';
import '../models/event_note_model.dart';
import '../models/event_media_model.dart';
import '../models/event_attachment_model.dart';
import '../services/event_detail_service_interface.dart';

class EventDetailRepository {
  final IEventDetailService _detailService;

  EventDetailRepository(this._detailService);

  Future<List<EventNoteModel>> getNotesByEventId(int eventId) {
    return _detailService.getNotesByEventId(eventId);
  }

  Future<List<EventMediaModel>> getMediaByEventId(int eventId) {
    return _detailService.getMediaByEventId(eventId);
  }

  Future<List<EventAttachmentModel>> getAttachmentsByEventId(int eventId) {
    return _detailService.getAttachmentsByEventId(eventId);
  }

  Future<void> addNote(int eventId, EventNoteModel note) {
    return _detailService.addNote(eventId, note);
  }

  Future<void> deleteNote(int noteId) {
    return _detailService.deleteNote(noteId);
  }

  Future<void> addAttachment(int eventId, EventAttachmentModel attachment) {
    return _detailService.addAttachment(eventId, attachment);
  }
}
