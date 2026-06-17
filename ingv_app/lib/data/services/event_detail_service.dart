import '../models/event_model.dart';
import '../models/event_note_model.dart';
import '../models/event_media_model.dart';
import '../models/event_attachment_model.dart';
import '../models/note_reply_model.dart';
import 'event_detail_service_interface.dart';

class EventDetailService implements IEventDetailService {
  // Hardcoded placeholder data for now - this will be replaced with real backend calls later

  static final Map<int, List<EventNoteModel>> _mockNotes = {
    1000: [
      EventNoteModel(
        noteId: 1,
        text:
            'Strong explosive activity with sustained ash plume. Ash column reached approx. 8 km above crater. Winds carrying ash SE. Monitoring continues.',
        author: 'Observatory Team',
        timestamp: DateTime(2026, 5, 14, 13, 55),
      ),
      EventNoteModel(
        noteId: 2,
        text:
            'Ash cloud increasing toward nearby crater zone. Visibility reduced.',
        author: 'Observatory Team',
        timestamp: DateTime(2026, 5, 14, 12, 35),
      ),
      EventNoteModel(
        noteId: 3,
        text: 'Activity decreased after peak phase. No new lava flow detected.',
        author: 'Observatory Team',
        timestamp: DateTime(2026, 5, 14, 13, 20),
      ),
    ],
  };

  static final Map<int, List<EventMediaModel>> _mockMedia = {
    1000: [
      EventMediaModel(
        mediaId: 1,
        title: 'Ash plume',
        mediaType: 'image',
        url: 'assets/images/ash_plume.jpg',
        timestamp: DateTime(2026, 5, 14, 10, 47),
      ),
      EventMediaModel(
        mediaId: 2,
        title: 'Crater view',
        mediaType: 'image',
        url: 'assets/images/crater_view.jpg',
        timestamp: DateTime(2026, 5, 14, 11, 5),
      ),
      EventMediaModel(
        mediaId: 3,
        title: 'Thermal image',
        mediaType: 'image',
        url: 'assets/images/thermal_image.jpg',
        timestamp: DateTime(2026, 5, 14, 12, 12),
      ),
      EventMediaModel(
        mediaId: 4,
        title: 'Satellite view',
        mediaType: 'image',
        url: 'assets/images/satellite_view.jpg',
        timestamp: DateTime(2026, 5, 14, 13, 20),
      ),
      EventMediaModel(
        mediaId: 5,
        title: 'Eruption overview',
        mediaType: 'video',
        url: 'assets/videos/eruption_overview.mp4',
        timestamp: DateTime(2026, 5, 14, 10, 48),
      ),
    ],
  };

  static final Map<int, List<EventAttachmentModel>> _mockAttachments = {
    1000: [
      EventAttachmentModel(
        attachmentId: 1,
        fileName: 'gas_readings_1210.csv',
        fileSizeBytes: 12 * 1024,
        fileType: 'csv',
        uploadedAt: DateTime(2026, 5, 14, 13, 55),
      ),
      EventAttachmentModel(
        attachmentId: 2,
        fileName: 'seismic_summary.pdf',
        fileSizeBytes: 245 * 1024,
        fileType: 'pdf',
        uploadedAt: DateTime(2026, 5, 14, 13, 55),
      ),
      EventAttachmentModel(
        attachmentId: 3,
        fileName: 'ash_sample_lab.pdf',
        fileSizeBytes: int.parse((1.2 * 1024 * 1024).toStringAsFixed(0)),
        fileType: 'pdf',
        uploadedAt: DateTime(2026, 5, 14, 13, 55),
      ),
      EventAttachmentModel(
        attachmentId: 4,
        fileName: 'gas_readings_1210.csv',
        fileSizeBytes: 12 * 1024,
        fileType: 'csv',
        uploadedAt: DateTime(2026, 5, 14, 13, 55),
      ),
      EventAttachmentModel(
        attachmentId: 5,
        fileName: 'seismic_summary.pdf',
        fileSizeBytes: 245 * 1024,
        fileType: 'pdf',
        uploadedAt: DateTime(2026, 5, 14, 13, 55),
      ),
      EventAttachmentModel(
        attachmentId: 6,
        fileName: 'ash_sample_lab.pdf',
        fileSizeBytes: int.parse((1.2 * 1024 * 1024).toStringAsFixed(0)),
        fileType: 'pdf',
        uploadedAt: DateTime(2026, 5, 14, 13, 55),
      ),
    ],
  };

  @override
  Future<List<EventNoteModel>> getNotesByEventId(int eventId) async {
    return _mockNotes[1000] ?? [];
  }

  @override
  Future<List<EventMediaModel>> getMediaByEventId(int eventId) async {
    return _mockMedia[eventId] ?? [];
  }

  @override
  Future<List<EventAttachmentModel>> getAttachmentsByEventId(
    int eventId,
  ) async {
    return _mockAttachments[eventId] ?? [];
  }

  @override
  Future<void> addNote(int eventId, EventNoteModel note) async {
    _mockNotes.putIfAbsent(eventId, () => []);
    _mockNotes[eventId]!.add(note);
  }

  @override
  Future<void> deleteNote(int noteId) async {
    for (var notes in _mockNotes.values) {
      notes.removeWhere((n) => n.noteId == noteId);
    }
    _mockReplies.removeWhere((reply) => reply.noteId == noteId);
  }

  @override
  Future<void> addMedia(int eventId, EventMediaModel media) async {
    _mockMedia.putIfAbsent(eventId, () => []);
    _mockMedia[eventId]!.add(media);
  }

  @override
  Future<void> addAttachment(
    int eventId,
    EventAttachmentModel attachment,
  ) async {
    _mockAttachments.putIfAbsent(eventId, () => []);
    _mockAttachments[eventId]!.add(attachment);
  }

  // -- Note reply CRUD --

  final List<NoteReplyModel> _mockReplies = [];
  int _nextReplyId = 1;

  @override
  Future<List<NoteReplyModel>> getRepliesByNoteId(int noteId) async {
    return _mockReplies.where((r) => r.noteId == noteId).toList();
  }

  @override
  Future<void> addReply(NoteReplyModel reply) async {
    _mockReplies.add(reply);
  }

  @override
  Future<void> deleteReply(int replyId) async {
    _mockReplies.removeWhere((r) => r.id == replyId);
  }

  /// Helper: create and save a new reply with an auto-assigned id.
  Future<NoteReplyModel> createReply({
    required int noteId,
    required String author,
    required String text,
  }) async {
    final reply = NoteReplyModel(
      id: _nextReplyId++,
      noteId: noteId,
      author: author,
      text: text,
      timestamp: DateTime.now(),
    );
    await addReply(reply);
    return reply;
  }
}
