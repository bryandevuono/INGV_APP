import '../models/event_model.dart';
import '../models/event_note_model.dart';
import '../models/event_media_model.dart';
import '../models/event_attachment_model.dart';
import '../models/note_reply_model.dart';

abstract class IEventDetailService {
  Future<List<EventNoteModel>> getNotesByEventId(int eventId);
  Future<List<EventMediaModel>> getMediaByEventId(int eventId);
  Future<List<EventAttachmentModel>> getAttachmentsByEventId(int eventId);
  Future<void> addNote(int eventId, EventNoteModel note);
  Future<void> deleteNote(int noteId);
  Future<void> addMedia(int eventId, EventMediaModel media);
  Future<void> addAttachment(int eventId, EventAttachmentModel attachment);
  Future<List<NoteReplyModel>> getRepliesByNoteId(int noteId);
  Future<void> addReply(NoteReplyModel reply);
  Future<void> deleteReply(int replyId);
}
