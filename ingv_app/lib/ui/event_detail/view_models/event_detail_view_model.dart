import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/models/event_note_model.dart';
import 'package:ingv_app/data/models/event_media_model.dart';
import 'package:ingv_app/data/models/event_attachment_model.dart';
import 'package:ingv_app/data/repositories/event_detail_repository.dart';

class EventDetailViewModel extends ChangeNotifier {
  final EventDetailRepository _detailRepository;

  EventModel? selectedEvent;
  List<EventNoteModel> notes = [];
  List<EventMediaModel> media = [];
  List<EventAttachmentModel> attachments = [];

  bool isLoading = false;

  EventDetailViewModel(this._detailRepository);

  Future<void> loadEventDetails(EventModel event) async {
    selectedEvent = event;
    isLoading = true;
    notifyListeners();

    try {
      final [notesList, mediaList, attachmentsList] = await Future.wait([
        _detailRepository.getNotesByEventId(event.eventId),
        _detailRepository.getMediaByEventId(event.eventId),
        _detailRepository.getAttachmentsByEventId(event.eventId),
      ]);

      notes = notesList as List<EventNoteModel>;
      media = mediaList as List<EventMediaModel>;
      attachments = attachmentsList as List<EventAttachmentModel>;
    } catch (e) {
      // Handle error
      notes = [];
      media = [];
      attachments = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNote(String noteText, String author) async {
    if (selectedEvent == null) return;

    final newNote = EventNoteModel(
      noteId: notes.length + 1,
      text: noteText,
      author: author,
      timestamp: DateTime.now(),
    );

    await _detailRepository.addNote(selectedEvent!.eventId, newNote);
    notes.add(newNote);
    notifyListeners();
  }

  Future<void> deleteNote(int noteId) async {
    await _detailRepository.deleteNote(noteId);
    notes.removeWhere((n) => n.noteId == noteId);
    notifyListeners();
  }

  void clearEventDetails() {
    selectedEvent = null;
    notes = [];
    media = [];
    attachments = [];
    notifyListeners();
  }

  String get eventDuration {
    if (selectedEvent == null) return '';
    if (selectedEvent!.endDt == null) return 'Ongoing';

    final duration = selectedEvent!.endDt!.difference(selectedEvent!.startDt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  bool get isEventEnded => selectedEvent?.endDt != null;

  String get eventStatusLabel => isEventEnded ? 'Ended' : 'Ongoing';

  String get eventLocationDisplay {
    if (selectedEvent == null) return '';
    return '${selectedEvent!.lat.toStringAsFixed(6)}, ${selectedEvent!.long.toStringAsFixed(6)}';
  }
}
