import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/attachment_type.dart';
import 'package:ingv_app/data/models/event_attachment.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/models/event_note_model.dart';
import 'package:ingv_app/data/models/note_reply_model.dart';
import 'package:ingv_app/data/repositories/attachment_repository_interface.dart';
import 'package:ingv_app/data/repositories/event_detail_repository.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/data/services/file_operations_interface.dart';
import 'package:ingv_app/data/services/export_service.dart';
import 'package:ingv_app/data/services/file_picker_service.dart';

class EventDetailViewModel extends ChangeNotifier {
  final IEventDetailRepository _detailRepository;
  final IEventRepository _eventRepository;
  final IAttachmentRepository _attachmentRepository;
  final ILocalFileService _localFileService;
  final IFileOpenService _fileOpenService;
  final IFilePickerService _filePickerService;
  late final IPdfExportService _pdfExportService;
  late final IZipExportService _zipExportService;

  EventModel? selectedEvent;
  List<EventNoteModel> notes = [];
  List<NoteReplyModel> replies = [];
  List<EventAttachment> attachments = [];
  EventAttachment? selectedAttachment;
  String? groupName;

  // Default category colors (consistent with timeview_model.dart)
  static const Map<String, Color> _defaultCategoryColors = {
    'Volcanic': Colors.red,
    'Earthquake': Colors.green,
    'Hydrological': Colors.blue,
    'Meteorological': Colors.orange,
    'Geological': Colors.brown,
    'Atmospheric': Colors.teal,
  };

  /// Returns the color for the currently selected event's category.
  Color get categoryColor {
    final event = selectedEvent;
    if (event == null) return Colors.red;
    return _defaultCategoryColors[event.category] ?? Colors.grey;
  }

  bool isLoading = false;
  bool isExporting = false;
  String? errorMessage;
  String? lastSavedAttachmentPath;
  String? lastExportPath;
  final Set<String> busyAttachmentIds = <String>{};

  EventDetailViewModel(
    this._detailRepository,
    this._attachmentRepository,
    this._localFileService,
    this._fileOpenService,
    this._eventRepository, [
    IFilePickerService? filePickerService,
    IPdfExportService? pdfExportService,
    IZipExportService? zipExportService,
  ]) : _filePickerService = filePickerService ?? FilePickerService() {
    _pdfExportService =
        pdfExportService ??
        PdfExportService(
          _detailRepository,
          _attachmentRepository,
          _localFileService,
        );
    _zipExportService =
        zipExportService ??
        ZipExportService(
          pdfExportService: _pdfExportService,
          detailRepository: _detailRepository,
          attachmentRepository: _attachmentRepository,
          localFileService: _localFileService,
        );
  }

  IEventRepository get eventRepository => _eventRepository;

  Future<void> loadEventDetails(EventModel event) async {
    groupName = await _eventRepository.getGroupOfEvent(event.eventId);
    selectedEvent = event;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final [notesList, attachmentsList] = await Future.wait([
        _detailRepository.getNotesByEventId(event.eventId),
        _attachmentRepository.getAttachmentsForEvent(event.eventId.toString()),
      ]);

      notes = notesList as List<EventNoteModel>;
      attachments = attachmentsList as List<EventAttachment>;

      // Load replies for all notes
      await loadRepliesForCurrentNotes();
    } catch (e) {
      errorMessage = 'Failed to load event details.';
      notes = [];
      attachments = [];
      replies = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSelectedEvent(EventModel updatedEvent) async {
    selectedEvent = updatedEvent;
    try {
      groupName = await _eventRepository.getGroupOfEvent(updatedEvent.eventId);
    } catch (e) {
      groupName = null;
    }
    notifyListeners();
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

  /// Delete a single reply from a note.
  Future<void> deleteReply(int replyId) async {
    await _detailRepository.deleteReply(replyId);
    replies.removeWhere((reply) => reply.id == replyId);
    notifyListeners();
  }

  /// Delete a note and all of its replies.
  Future<void> deleteNote(int noteId) async {
    final noteReplies = replies
        .where((reply) => reply.noteId == noteId)
        .toList();
    for (final reply in noteReplies) {
      await _detailRepository.deleteReply(reply.id);
    }

    await _detailRepository.deleteNote(noteId);
    notes.removeWhere((n) => n.noteId == noteId);
    replies.removeWhere((reply) => reply.noteId == noteId);
    notifyListeners();
  }

  /// Load all replies for every note currently in the notes list.
  Future<void> loadRepliesForCurrentNotes() async {
    replies = [];
    try {
      for (final note in notes) {
        final noteReplies = await _detailRepository.getRepliesByNoteId(
          note.noteId,
        );
        replies.addAll(noteReplies);
      }
    } catch (_) {
      replies = [];
    }
  }

  /// Add a reply to a given note.
  Future<void> addReply({
    required int noteId,
    required String author,
    required String text,
  }) async {
    final reply = NoteReplyModel(
      id: DateTime.now().microsecondsSinceEpoch,
      noteId: noteId,
      author: author,
      text: text,
      timestamp: DateTime.now(),
    );
    await _detailRepository.addReply(reply);
    replies.add(reply);
    notifyListeners();
  }

  /// Get all replies for a specific note.
  List<NoteReplyModel> getRepliesForNote(int noteId) {
    return replies.where((r) => r.noteId == noteId).toList();
  }

  Future<void> deleteAttachment(EventAttachment attachment) async {
    await _attachmentRepository.deleteAttachment(attachment.id);
    attachments.removeWhere((item) => item.id == attachment.id);
    if (selectedAttachment?.id == attachment.id) {
      selectedAttachment = null;
    }
    notifyListeners();
  }

  List<EventAttachment> get imageAttachments {
    return attachments
        .where((attachment) => attachment.type == AttachmentType.image)
        .toList();
  }

  List<EventAttachment> get videoAttachments {
    return attachments
        .where((attachment) => attachment.type == AttachmentType.video)
        .toList();
  }

  List<EventAttachment> get fileAttachments {
    return attachments.where((attachment) => attachment.isFile).toList();
  }

  void selectAttachment(EventAttachment? attachment) {
    selectedAttachment = attachment;
    notifyListeners();
  }

  bool isAttachmentBusy(String attachmentId) {
    return busyAttachmentIds.contains(attachmentId);
  }

  Future<void> addMediaFromFiles(String mediaType, List<File> files) async {
    if (selectedEvent == null) return;

    for (final file in files) {
      final attachment = EventAttachment(
        id: 'local_${DateTime.now().microsecondsSinceEpoch}',
        eventId: selectedEvent!.eventId.toString(),
        fileName: file.path.split(Platform.pathSeparator).last,
        localPath: file.path,
        type: mediaType == 'video'
            ? AttachmentType.video
            : AttachmentType.image,
        sizeBytes: file.existsSync() ? file.lengthSync() : null,
        mimeType: mediaType == 'video' ? 'video/*' : 'image/*',
        createdAt: DateTime.now(),
      );

      await _attachmentRepository.addAttachment(attachment);
      attachments.add(attachment);
    }

    notifyListeners();
  }

  Future<void> addAttachmentFromFiles(List<File> files) async {
    if (selectedEvent == null) return;

    for (final file in files) {
      final fileName = file.path.split('/').last;
      final fileSize = file.lengthSync();
      final fileExtension = fileName.split('.').last.toLowerCase();

      final newAttachment = EventAttachment(
        id: 'local_${DateTime.now().microsecondsSinceEpoch}',
        eventId: selectedEvent!.eventId.toString(),
        fileName: fileName,
        localPath: file.path,
        type: parseAttachmentTypeFromExtension(fileExtension),
        sizeBytes: fileSize,
        mimeType: _guessMimeType(fileExtension),
        createdAt: DateTime.now(),
      );

      await _attachmentRepository.addAttachment(newAttachment);
      attachments.add(newAttachment);
    }

    notifyListeners();
  }

  Future<void> pickAndAddMedia(String mediaType) async {
    List<File> files = [];
    if (mediaType == 'image') {
      files = await _filePickerService.pickImages();
    } else if (mediaType == 'video') {
      files = await _filePickerService.pickVideos();
    }

    if (files.isNotEmpty) {
      await addMediaFromFiles(mediaType, files);
    }
  }

  Future<void> pickAndAddAttachment() async {
    final files = await _filePickerService.pickFiles();
    if (files.isNotEmpty) {
      await addAttachmentFromFiles(files);
    }
  }

  Future<String?> resolveAttachmentPath(EventAttachment attachment) async {
    errorMessage = null;
    busyAttachmentIds.add(attachment.id);
    notifyListeners();

    try {
      final path = await _localFileService.resolvePath(attachment);
      if (path == null) {
        errorMessage = 'Local file not found for ${attachment.fileName}.';
      }
      return path;
    } catch (e) {
      errorMessage = 'Could not load ${attachment.fileName}.';
      return null;
    } finally {
      busyAttachmentIds.remove(attachment.id);
      notifyListeners();
    }
  }

  Future<bool> openAttachment(EventAttachment attachment) async {
    errorMessage = null;
    busyAttachmentIds.add(attachment.id);
    notifyListeners();

    try {
      final path = await _localFileService.resolvePath(attachment);
      if (path == null) {
        errorMessage = 'Local file not found for ${attachment.fileName}.';
        return false;
      }
      final didOpen = await _fileOpenService.openFile(path);
      if (!didOpen) {
        errorMessage = 'Could not open ${attachment.fileName}.';
      }
      return didOpen;
    } catch (e) {
      errorMessage = 'Could not open ${attachment.fileName}.';
      return false;
    } finally {
      busyAttachmentIds.remove(attachment.id);
      notifyListeners();
    }
  }

  Future<String?> saveAttachmentCopy(EventAttachment attachment) async {
    errorMessage = null;
    lastSavedAttachmentPath = null;
    busyAttachmentIds.add(attachment.id);
    notifyListeners();

    try {
      lastSavedAttachmentPath = await _localFileService.saveAttachmentCopy(
        attachment,
      );
      if (lastSavedAttachmentPath == null) {
        errorMessage = 'Could not save a local copy of ${attachment.fileName}.';
      }
      return lastSavedAttachmentPath;
    } catch (e) {
      errorMessage = 'Could not save a local copy of ${attachment.fileName}.';
      return null;
    } finally {
      busyAttachmentIds.remove(attachment.id);
      notifyListeners();
    }
  }

  Future<String?> exportSelectedEvent() async {
    if (selectedEvent == null) {
      errorMessage = 'No event selected for export.';
      notifyListeners();
      return null;
    }

    isExporting = true;
    errorMessage = null;
    lastExportPath = null;
    notifyListeners();

    try {
      final result = await _pdfExportService.exportEventReport(
        event: selectedEvent!,
        groupName: groupName,
      );
      lastExportPath = result.saveLocation;
      return lastExportPath;
    } catch (e) {
      errorMessage = 'Failed to export event PDF.';
      return null;
    } finally {
      isExporting = false;
      notifyListeners();
    }
  }

  Future<String?> exportSelectedEventAsZip() async {
    if (selectedEvent == null) {
      errorMessage = 'No event selected for export.';
      notifyListeners();
      return null;
    }

    isExporting = true;
    errorMessage = null;
    lastExportPath = null;
    notifyListeners();

    try {
      final result = await _zipExportService.exportEventAsZip(
        event: selectedEvent!,
        groupName: groupName,
        notes: notes,
        attachments: attachments,
      );
      lastExportPath = result.saveLocation;
      return lastExportPath;
    } catch (e) {
      errorMessage = 'Failed to export event ZIP.';
      return null;
    } finally {
      isExporting = false;
      notifyListeners();
    }
  }

  void clearEventDetails() {
    selectedEvent = null;
    notes = [];
    attachments = [];
    selectedAttachment = null;
    groupName = null;
    errorMessage = null;
    lastSavedAttachmentPath = null;
    lastExportPath = null;
    busyAttachmentIds.clear();
    notifyListeners();
  }

  String _guessMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return 'image/$extension';
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
      case 'webm':
        return 'video/$extension';
      case 'pdf':
        return 'application/pdf';
      case 'csv':
        return 'text/csv';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
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

  Future<void> getGroupofEvent() async {
    if (selectedEvent == null) return;
    try {
      groupName = await _eventRepository.getGroupOfEvent(
        selectedEvent!.eventId,
      );
    } catch (e) {
      groupName = 'N/A';
    }
    notifyListeners();
  }
}
