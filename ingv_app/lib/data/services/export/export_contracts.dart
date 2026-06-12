import 'dart:typed_data';

import 'package:ingv_app/data/models/event_attachment.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/models/event_note_model.dart';

import 'export_result.dart';

abstract class ExportService {
  Future<ExportResult> exportEventReport({
    required EventModel event,
    String? groupName,
    bool saveToDisk = true,
  });

  Future<ExportResult> exportTimelineReport({
    required List<EventModel> events,
    required List<String> orderedCategories,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
    bool saveToDisk = true,
  });

  Future<bool> previewPdf(Uint8List bytes, {required String filename});

  Future<bool> sharePdf(Uint8List bytes, {required String filename});
}

abstract class IPdfExportService extends ExportService {
  Future<Uint8List> buildEventPdfBytes({
    required EventModel event,
    String? groupName,
    List<EventNoteModel>? notes,
    List<EventAttachment>? attachments,
  });

  Future<Uint8List> buildTimelinePdfBytes({
    required List<EventModel> events,
    required List<String> orderedCategories,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
  });
}

abstract class IZipExportService {
  Future<ExportResult> exportEventAsZip({
    required EventModel event,
    String? groupName,
    List<EventNoteModel>? notes,
    List<EventAttachment>? attachments,
  });

  Future<ExportResult> exportTimelineAsZip({
    required List<EventModel> events,
    required List<String> orderedCategories,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
  });
}
