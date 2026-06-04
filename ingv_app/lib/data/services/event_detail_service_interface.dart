import '../models/event_model.dart';
import '../models/event_note_model.dart';
import '../models/event_media_model.dart';
import '../models/event_attachment_model.dart';

abstract class IEventDetailService {
  Future<List<EventNoteModel>> getNotesByEventId(int eventId);
  Future<List<EventMediaModel>> getMediaByEventId(int eventId);
  Future<List<EventAttachmentModel>> getAttachmentsByEventId(int eventId);
  Future<void> addNote(int eventId, EventNoteModel note);
  Future<void> deleteNote(int noteId);
  Future<void> addAttachment(int eventId, EventAttachmentModel attachment);
}
