import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ingv_app/data/models/event_attachment.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/models/event_note_model.dart';
import 'package:ingv_app/data/repositories/attachment_repository_interface.dart';
import 'package:ingv_app/data/repositories/event_detail_repository.dart';
import 'package:ingv_app/data/services/export/export_contracts.dart';
import 'package:ingv_app/data/services/export/export_file_save_service.dart';
import 'package:ingv_app/data/services/export/export_result.dart';
import 'package:ingv_app/data/services/export/zip_archive_service.dart';
import 'package:ingv_app/data/services/file_operations_interface.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

export 'package:ingv_app/data/services/export/export_contracts.dart';
export 'package:ingv_app/data/services/export/export_file_save_service.dart';
export 'package:ingv_app/data/services/export/export_result.dart';
export 'package:ingv_app/data/services/export/zip_archive_service.dart';

class PdfExportService implements IPdfExportService {
  final IEventDetailRepository _detailRepository;
  final IAttachmentRepository _attachmentRepository;
  final ILocalFileService _localFileService;
  final IExportFileSaveService _fileSaveService;

  PdfExportService(
    this._detailRepository,
    this._attachmentRepository,
    this._localFileService, [
    IExportFileSaveService? fileSaveService,
  ]) : _fileSaveService = fileSaveService ?? FileSaverExportFileSaveService();

  @override
  Future<Uint8List> buildEventPdfBytes({
    required EventModel event,
    String? groupName,
    List<EventNoteModel>? notes,
    List<EventAttachment>? attachments,
  }) async {
    final effectiveNotes =
        notes ?? await _detailRepository.getNotesByEventId(event.eventId);
    final effectiveAttachments =
        attachments ??
        await _attachmentRepository.getAttachmentsForEvent(
          event.eventId.toString(),
        );

    return _buildEventPdfBytes(
      event: event,
      groupName: groupName,
      notes: effectiveNotes,
      attachments: effectiveAttachments,
    );
  }

  @override
  Future<Uint8List> buildTimelinePdfBytes({
    required List<EventModel> events,
    required List<String> orderedCategories,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
  }) async {
    final details = <int, _TimelineEventDetail>{};
    for (final event in events) {
      final [notesList, attachmentsList] = await Future.wait([
        _detailRepository.getNotesByEventId(event.eventId),
        _attachmentRepository.getAttachmentsForEvent(event.eventId.toString()),
      ]);
      details[event.eventId] = _TimelineEventDetail(
        notes: notesList as List<EventNoteModel>,
        attachments: attachmentsList as List<EventAttachment>,
      );
    }

    return _buildTimelinePdfBytes(
      events: events,
      orderedCategories: orderedCategories,
      filterStartDate: filterStartDate,
      filterEndDate: filterEndDate,
      eventDetails: details,
    );
  }

  @override
  Future<ExportResult> exportEventReport({
    required EventModel event,
    String? groupName,
    bool saveToDisk = true,
  }) async {
    try {
      final bytes = await buildEventPdfBytes(
        event: event,
        groupName: groupName,
      );
      final exportDate = DateTime.now();
      final fileName = _buildFileName('event_export', event.title, exportDate);
      final saveLocation = saveToDisk ? await _savePdf(bytes, fileName) : '';

      return ExportResult(
        fileName: fileName,
        saveLocation: saveLocation,
        bytes: bytes,
      );
    } catch (error) {
      throw Exception('Failed to export event report: $error');
    }
  }

  @override
  Future<ExportResult> exportTimelineReport({
    required List<EventModel> events,
    required List<String> orderedCategories,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
    bool saveToDisk = true,
  }) async {
    try {
      final bytes = await buildTimelinePdfBytes(
        events: events,
        orderedCategories: orderedCategories,
        filterStartDate: filterStartDate,
        filterEndDate: filterEndDate,
      );
      final exportDate = DateTime.now();
      final fileName = _buildFileName(
        'timeline_export',
        filterStartDate != null || filterEndDate != null
            ? _buildTimelineDateRange(filterStartDate, filterEndDate)
            : 'all_events',
        exportDate,
      );
      final saveLocation = saveToDisk ? await _savePdf(bytes, fileName) : '';

      return ExportResult(
        fileName: fileName,
        saveLocation: saveLocation,
        bytes: bytes,
      );
    } catch (error) {
      throw Exception('Failed to export timeline report: $error');
    }
  }

  @override
  Future<bool> previewPdf(Uint8List bytes, {required String filename}) {
    return Printing.layoutPdf(name: filename, onLayout: (_) async => bytes);
  }

  @override
  Future<bool> sharePdf(Uint8List bytes, {required String filename}) {
    return Printing.sharePdf(bytes: bytes, filename: filename);
  }

  Future<Uint8List> _buildEventPdfBytes({
    required EventModel event,
    String? groupName,
    required List<EventNoteModel> notes,
    required List<EventAttachment> attachments,
  }) async {
    final resolvedImages = await _resolveAttachments(
      attachments.where((attachment) => attachment.isPreviewable).toList(),
      loadBinaryData: true,
    );
    final resolvedVideos = await _resolveAttachments(
      attachments.where((attachment) => attachment.isVideo).toList(),
      loadPreviewData: true,
    );

    final document = pw.Document(theme: await _buildPdfTheme());
    final exportDate = DateTime.now();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(
            title: event.title,
            subtitle: 'Event PDF report',
            exportDate: exportDate,
          ),
          pw.SizedBox(height: 16),
          _buildMetadataTable([
            ['Category', event.category],
            ['Status', event.endDt == null ? 'Ongoing' : 'Ended'],
            ['Start', _formatDateTime(event.startDt)],
            ['End', _formatDateTime(event.endDt)],
            ['Duration', _formatDuration(event.startDt, event.endDt)],
            ['Author / Initiator', _fallback(event.author)],
            ['Team', _fallback(groupName)],
            [
              'Location coordinates',
              '${event.lat.toStringAsFixed(6)}, ${event.long.toStringAsFixed(6)}',
            ],
          ]),
          pw.SizedBox(height: 16),
          _buildTextSection('Description', _fallback(event.description)),
          pw.SizedBox(height: 16),
          _buildNotesSection(notes),
          pw.SizedBox(height: 16),
          _buildImageSection(resolvedImages),
          pw.SizedBox(height: 16),
          _buildVideoSection(resolvedVideos),
          pw.SizedBox(height: 16),
          _buildFileSection(
            attachments.where((attachment) => attachment.isFile).toList(),
          ),
          pw.SizedBox(height: 16),
          _buildTodoSection(),
        ],
      ),
    );

    return document.save();
  }

  Future<Uint8List> _buildTimelinePdfBytes({
    required List<EventModel> events,
    required List<String> orderedCategories,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
    required Map<int, _TimelineEventDetail> eventDetails,
  }) async {
    final document = pw.Document(theme: await _buildPdfTheme());
    final exportDate = DateTime.now();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(
            title: _buildTimelineTitle(filterStartDate, filterEndDate),
            subtitle: 'Timeline PDF report',
            exportDate: exportDate,
          ),
          pw.SizedBox(height: 16),
          _buildMetadataTable([
            ['Event count', events.length.toString()],
            [
              'Date range',
              _buildTimelineDateRange(filterStartDate, filterEndDate),
            ],
          ]),
          pw.SizedBox(height: 16),
          _buildTimelineOverview(events, eventDetails),
          pw.SizedBox(height: 16),
          ..._buildTimelineGroups(events, orderedCategories, eventDetails),
          pw.SizedBox(height: 16),
          _buildTodoSection(),
        ],
      ),
    );

    return document.save();
  }

  Future<String> _savePdf(Uint8List bytes, String fileName) async {
    return _fileSaveService.savePdf(bytes, fileName);
  }

  Future<pw.ThemeData> _buildPdfTheme() async {
    if (defaultTargetPlatform != TargetPlatform.windows) {
      return pw.ThemeData.withFont();
    }

    final baseFont = await _loadWindowsFont('C:\\Windows\\Fonts\\segoeui.ttf');
    final boldFont =
        await _loadWindowsFont('C:\\Windows\\Fonts\\segoeuib.ttf') ?? baseFont;
    final italicFont =
        await _loadWindowsFont('C:\\Windows\\Fonts\\segoeuii.ttf') ?? baseFont;
    final boldItalicFont =
        await _loadWindowsFont('C:\\Windows\\Fonts\\segoeuiz.ttf') ?? boldFont;
    final symbolFallback = await _loadWindowsFont(
      'C:\\Windows\\Fonts\\seguisym.ttf',
    );
    final emojiFallback = await _loadWindowsFont(
      'C:\\Windows\\Fonts\\seguiemj.ttf',
    );

    final fallbacks = <pw.Font>[
      if (symbolFallback != null) symbolFallback,
      if (emojiFallback != null) emojiFallback,
    ];

    return pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
      italic: italicFont,
      boldItalic: boldItalicFont,
      fontFallback: fallbacks.isEmpty ? null : fallbacks,
    );
  }

  Future<pw.Font?> _loadWindowsFont(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return null;
      }
      final bytes = await file.readAsBytes();
      return pw.Font.ttf(bytes.buffer.asByteData());
    } catch (_) {
      return null;
    }
  }

  Future<List<_ResolvedAttachment>> _resolveAttachments(
    List<EventAttachment> attachments, {
    bool loadBinaryData = false,
    bool loadPreviewData = false,
  }) {
    return Future.wait(
      attachments.map(
        (attachment) => _resolveAttachment(
          attachment,
          loadBinaryData: loadBinaryData,
          loadPreviewData: loadPreviewData,
        ),
      ),
    );
  }

  Future<_ResolvedAttachment> _resolveAttachment(
    EventAttachment attachment, {
    bool loadBinaryData = false,
    bool loadPreviewData = false,
  }) async {
    final reference = await _resolveAttachmentReference(attachment);
    Uint8List? bytes;
    Uint8List? previewBytes;
    String? loadError;

    if (loadBinaryData) {
      try {
        bytes = await _loadAttachmentBytes(
          attachment,
          referenceOverride: reference,
        );
      } catch (_) {
        loadError = 'Image could not be loaded';
      }
    }

    if (loadPreviewData) {
      try {
        previewBytes = await _loadPreviewBytes(attachment);
      } catch (_) {
        loadError ??= 'Thumbnail could not be loaded';
      }
    }

    return _ResolvedAttachment(
      attachment: attachment,
      reference: reference,
      bytes: bytes,
      previewBytes: previewBytes,
      error: loadError,
    );
  }

  Future<String> _resolveAttachmentReference(EventAttachment attachment) async {
    if (attachment.localPath != null && attachment.localPath!.isNotEmpty) {
      return attachment.localPath!;
    }
    if (attachment.assetPath != null && attachment.assetPath!.isNotEmpty) {
      return attachment.assetPath!;
    }

    final resolvedPath = await _localFileService.resolvePath(attachment);
    return resolvedPath ?? 'Unavailable';
  }

  Future<Uint8List> _loadAttachmentBytes(
    EventAttachment attachment, {
    String? referenceOverride,
  }) async {
    if (attachment.localPath != null && attachment.localPath!.isNotEmpty) {
      return _loadBytesFromPath(attachment.localPath!);
    }
    if (attachment.assetPath != null && attachment.assetPath!.isNotEmpty) {
      return _loadBytesFromPath(attachment.assetPath!);
    }
    if (referenceOverride != null && referenceOverride != 'Unavailable') {
      return _loadBytesFromPath(referenceOverride);
    }
    throw Exception('Attachment bytes unavailable');
  }

  Future<Uint8List?> _loadPreviewBytes(EventAttachment attachment) async {
    if (attachment.thumbnailPath == null || attachment.thumbnailPath!.isEmpty) {
      return null;
    }

    try {
      return _loadBytesFromPath(attachment.thumbnailPath!);
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> _loadBytesFromPath(String path) async {
    if (_looksLikeAssetPath(path)) {
      final assetData = await rootBundle.load(path);
      return assetData.buffer.asUint8List();
    }

    final file = File(path);
    if (!await file.exists()) {
      throw Exception('File does not exist');
    }
    return file.readAsBytes();
  }

  bool _looksLikeAssetPath(String path) {
    return !path.contains(':') &&
        !path.startsWith('/') &&
        !path.startsWith('\\');
  }

  pw.Widget _buildReportHeader({
    required String title,
    required String subtitle,
    required DateTime exportDate,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          subtitle,
          style: pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Exported: ${_formatDateTime(exportDate)}',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  pw.Widget _buildMetadataTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: rows
          .map(
            (row) => pw.TableRow(
              children: row.map((cell) {
                final isLabel = row.indexOf(cell) == 0;
                return pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    cell,
                    style: pw.TextStyle(
                      fontWeight: isLabel ? pw.FontWeight.bold : null,
                      fontSize: 10,
                    ),
                  ),
                );
              }).toList(),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _buildTextSection(String title, String body) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        pw.SizedBox(height: 8),
        pw.Text(body, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildNotesSection(List<EventNoteModel> notes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Notes and observations'),
        pw.SizedBox(height: 8),
        if (notes.isEmpty)
          pw.Text(
            'No notes available.',
            style: const pw.TextStyle(fontSize: 10),
          )
        else
          ...notes.map(
            (note) => pw.Container(
              width: double.infinity,
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${_fallback(note.author)} - ${_formatDateTime(note.timestamp)}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(note.text, style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildImageSection(List<_ResolvedAttachment> images) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Attached images'),
        pw.SizedBox(height: 8),
        if (images.isEmpty)
          pw.Text(
            'No images attached.',
            style: const pw.TextStyle(fontSize: 10),
          )
        else
          pw.Wrap(
            spacing: 12,
            runSpacing: 12,
            children: images.map(_buildImageCard).toList(),
          ),
      ],
    );
  }

  pw.Widget _buildImageCard(_ResolvedAttachment image) {
    final attachment = image.attachment;
    if (image.bytes == null) {
      return _buildUnavailableAttachmentCard(
        title: attachment.fileName,
        type: attachment.mimeType ?? attachment.fileExtension,
        reference: image.reference,
        message: image.error ?? 'Image could not be loaded',
      );
    }

    return pw.Container(
      width: 240,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.ClipRRect(
            horizontalRadius: 4,
            verticalRadius: 4,
            child: pw.Image(
              pw.MemoryImage(image.bytes!),
              height: 140,
              width: 224,
              fit: pw.BoxFit.cover,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            attachment.fileName,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            '${attachment.mimeType ?? attachment.fileExtension} | ${attachment.formattedSize}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Reference: ${image.reference}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildVideoSection(List<_ResolvedAttachment> videos) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Attached videos'),
        pw.SizedBox(height: 8),
        if (videos.isEmpty)
          pw.Text(
            'No videos attached.',
            style: const pw.TextStyle(fontSize: 10),
          )
        else
          ...videos.map(_buildVideoCard),
      ],
    );
  }

  pw.Widget _buildVideoCard(_ResolvedAttachment video) {
    final attachment = video.attachment;
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 120,
            height: 80,
            color: PdfColors.grey200,
            child: video.previewBytes == null
                ? pw.Center(
                    child: pw.Text(
                      'Thumbnail unavailable',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  )
                : pw.Stack(
                    alignment: pw.Alignment.center,
                    children: [
                      pw.Image(
                        pw.MemoryImage(video.previewBytes!),
                        fit: pw.BoxFit.cover,
                        width: 120,
                        height: 80,
                      ),
                      pw.Container(
                        color: PdfColor.fromInt(0x66000000),
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: pw.Text(
                          'PLAY',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  attachment.fileName,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Type: ${attachment.mimeType ?? attachment.fileExtension}',
                ),
                pw.Text('Path/reference: ${video.reference}'),
                pw.Text('File size: ${attachment.formattedSize}'),
                pw.Text('Duration: Unavailable'),
                if (video.error != null)
                  pw.Text(
                    video.error!,
                    style: const pw.TextStyle(
                      color: PdfColors.red700,
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFileSection(List<EventAttachment> files) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Attached files and documents'),
        pw.SizedBox(height: 8),
        if (files.isEmpty)
          pw.Text('No files attached.', style: const pw.TextStyle(fontSize: 10))
        else
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(3),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              _buildFileRow([
                'File name',
                'Type',
                'Size',
                'Path/reference',
                'Attached date',
              ], isHeader: true),
              ...files.map(
                (attachment) => _buildFileRow([
                  attachment.fileName,
                  attachment.mimeType ?? attachment.fileExtension,
                  attachment.formattedSize,
                  attachment.localPath ?? attachment.assetPath ?? 'Unavailable',
                  _formatDateTime(attachment.createdAt),
                ]),
              ),
            ],
          ),
      ],
    );
  }

  pw.TableRow _buildFileRow(List<String> cells, {bool isHeader = false}) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: isHeader ? PdfColors.grey200 : PdfColors.white,
      ),
      children: cells
          .map(
            (cell) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                cell,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: isHeader ? pw.FontWeight.bold : null,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _buildUnavailableAttachmentCard({
    required String title,
    required String type,
    required String reference,
    required String message,
  }) {
    return pw.Container(
      width: 240,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Type: $type', style: const pw.TextStyle(fontSize: 9)),
          pw.Text(
            'Reference: $reference',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            message,
            style: const pw.TextStyle(color: PdfColors.red700, fontSize: 9),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTimelineOverview(
    List<EventModel> events,
    Map<int, _TimelineEventDetail> eventDetails,
  ) {
    final ongoingCount = events.where((event) => event.endDt == null).length;
    final completedCount = events.length - ongoingCount;
    final noteCount = eventDetails.values.fold<int>(
      0,
      (count, detail) => count + detail.notes.length,
    );
    final attachmentCount = eventDetails.values.fold<int>(
      0,
      (count, detail) => count + detail.attachments.length,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Overview'),
        pw.SizedBox(height: 8),
        _buildMetadataTable([
          ['Ongoing events', ongoingCount.toString()],
          ['Completed events', completedCount.toString()],
          ['Notes captured', noteCount.toString()],
          ['Attachments referenced', attachmentCount.toString()],
        ]),
      ],
    );
  }

  List<pw.Widget> _buildTimelineGroups(
    List<EventModel> events,
    List<String> orderedCategories,
    Map<int, _TimelineEventDetail> eventDetails,
  ) {
    final categories = orderedCategories.isNotEmpty
        ? orderedCategories
        : events.map((event) => event.category).toSet().toList();
    final widgets = <pw.Widget>[];

    for (final category in categories) {
      final categoryEvents =
          events.where((event) => event.category.trim() == category).toList()
            ..sort((left, right) => left.startDt.compareTo(right.startDt));

      if (categoryEvents.isEmpty) {
        continue;
      }

      widgets.add(_buildSectionTitle('Category: $category'));
      widgets.add(pw.SizedBox(height: 8));
      widgets.addAll(
        categoryEvents.map(
          (event) => _buildTimelineEventCard(
            event,
            eventDetails[event.eventId] ??
                const _TimelineEventDetail(notes: [], attachments: []),
          ),
        ),
      );
      widgets.add(pw.SizedBox(height: 12));
    }

    return widgets;
  }

  pw.Widget _buildTimelineEventCard(
    EventModel event,
    _TimelineEventDetail detail,
  ) {
    final imageCount = detail.attachments
        .where((attachment) => attachment.isPreviewable)
        .length;
    final videoCount = detail.attachments
        .where((attachment) => attachment.isVideo)
        .length;
    final fileCount = detail.attachments
        .where((attachment) => attachment.isFile)
        .length;
    final noteSummary = detail.notes.isEmpty
        ? 'No notes available.'
        : detail.notes
              .take(3)
              .map((note) => note.text.trim())
              .where((text) => text.isNotEmpty)
              .join(' | ');

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            event.title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Start: ${_formatDateTime(event.startDt)}'),
          pw.Text('End: ${_formatDateTime(event.endDt)}'),
          pw.Text('Duration: ${_formatDuration(event.startDt, event.endDt)}'),
          pw.Text(
            'Location: ${event.lat.toStringAsFixed(6)}, ${event.long.toStringAsFixed(6)}',
          ),
          pw.Text(
            'Notes summary: ${noteSummary.isEmpty ? 'No notes available.' : noteSummary}',
          ),
          pw.Text(
            'Attachment summary: Images $imageCount, Videos $videoCount, Files $fileCount',
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTodoSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Future improvement'),
        pw.SizedBox(height: 6),
        pw.Text(
          'TODO: add optional ZIP export with this PDF and all original attachments.',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
    );
  }

  String _buildFileName(String prefix, String label, DateTime timestamp) {
    final datePart =
        '${timestamp.year}${_twoDigits(timestamp.month)}${_twoDigits(timestamp.day)}_${_twoDigits(timestamp.hour)}${_twoDigits(timestamp.minute)}';
    final sanitizedLabel = label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return '${prefix}_${sanitizedLabel.isEmpty ? 'report' : sanitizedLabel}_$datePart';
  }

  String _buildTimelineTitle(DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) {
      return 'All timeline events';
    }
    return 'Timeline ${_buildTimelineDateRange(startDate, endDate)}';
  }

  String _buildTimelineDateRange(DateTime? startDate, DateTime? endDate) {
    final start = startDate == null ? 'Any start' : _formatDateTime(startDate);
    final end = endDate == null ? 'Any end' : _formatDateTime(endDate);
    return '$start to $end';
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'N/A';
    }
    final local = dateTime.toLocal();
    return '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)} ${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
  }

  String _formatDuration(DateTime startDate, DateTime? endDate) {
    if (endDate == null) {
      return 'Ongoing';
    }

    final duration = endDate.difference(startDate);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) {
      return '${minutes}m';
    }
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _fallback(String? value) {
    if (value == null) {
      return 'N/A';
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'N/A' : trimmed;
  }
}

class ZipExportService implements IZipExportService {
  final IPdfExportService _pdfExportService;
  final IEventDetailRepository _detailRepository;
  final IAttachmentRepository _attachmentRepository;
  final ILocalFileService _localFileService;
  final IExportFileSaveService _fileSaveService;
  final IZipArchiveService _zipArchiveService;

  ZipExportService({
    required IPdfExportService pdfExportService,
    required IEventDetailRepository detailRepository,
    required IAttachmentRepository attachmentRepository,
    required ILocalFileService localFileService,
    IExportFileSaveService? fileSaveService,
    IZipArchiveService? zipArchiveService,
  }) : _pdfExportService = pdfExportService,
       _detailRepository = detailRepository,
       _attachmentRepository = attachmentRepository,
       _localFileService = localFileService,
       _fileSaveService = fileSaveService ?? FileSaverExportFileSaveService(),
       _zipArchiveService = zipArchiveService ?? ArchiveZipArchiveService();

  @override
  Future<ExportResult> exportEventAsZip({
    required EventModel event,
    String? groupName,
    List<EventNoteModel>? notes,
    List<EventAttachment>? attachments,
  }) async {
    final effectiveNotes = notes ?? await _fetchNotes(event.eventId);
    final effectiveAttachments =
        attachments ?? await _fetchAttachments(event.eventId.toString());
    final pdfBytes = await _pdfExportService.buildEventPdfBytes(
      event: event,
      groupName: groupName,
      notes: effectiveNotes,
      attachments: effectiveAttachments,
    );

    final usedPaths = <String>{'event_report.pdf', 'metadata/export_info.json'};
    final archiveEntries = <ExportArchiveEntry>[];
    final includedAttachmentFileNames = <String>[];
    final missingAttachmentFileNames = <String>[];

    _addBytesToArchive(archiveEntries, 'event_report.pdf', pdfBytes, usedPaths);

    for (final attachment in effectiveAttachments) {
      final resolved = await _resolveAttachmentBytes(attachment);
      if (resolved == null) {
        missingAttachmentFileNames.add(attachment.fileName);
        debugPrint('ZIP export: missing attachment ${attachment.fileName}');
        continue;
      }

      final archivePath = _eventAttachmentArchivePath(attachment);
      final uniqueArchivePath = _uniqueArchivePath(archivePath, usedPaths);
      _addBytesToArchive(
        archiveEntries,
        uniqueArchivePath,
        resolved,
        usedPaths,
      );
      includedAttachmentFileNames.add(uniqueArchivePath);
    }

    final metadata = <String, Object?>{
      'exportType': 'event',
      'exportDateTime': DateTime.now().toIso8601String(),
      'eventId': event.eventId,
      'eventTitle': event.title,
      'eventStartTime': event.startDt.toIso8601String(),
      'eventEndTime': event.endDt?.toIso8601String(),
      'noteCount': effectiveNotes.length,
      'attachmentCount': effectiveAttachments.length,
      'includedAttachmentFileNames': includedAttachmentFileNames,
      'missingAttachmentFileNames': missingAttachmentFileNames,
    };
    _addBytesToArchive(
      archiveEntries,
      'metadata/export_info.json',
      utf8.encode(JsonEncoder.withIndent('  ').convert(metadata)),
      usedPaths,
    );

    final zipBytes = _zipArchiveService.createZip(archiveEntries);
    final fileName = _buildEventZipFileName(event);
    final saveLocation = await _saveZip(zipBytes, fileName);

    return ExportResult(
      fileName: fileName,
      saveLocation: saveLocation,
      bytes: zipBytes,
    );
  }

  @override
  Future<ExportResult> exportTimelineAsZip({
    required List<EventModel> events,
    required List<String> orderedCategories,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
  }) async {
    final pdfBytes = await _pdfExportService.buildTimelinePdfBytes(
      events: events,
      orderedCategories: orderedCategories,
      filterStartDate: filterStartDate,
      filterEndDate: filterEndDate,
    );

    final usedPaths = <String>{
      'timeline_report.pdf',
      'data/events.json',
      'metadata/export_info.json',
    };
    final archiveEntries = <ExportArchiveEntry>[];
    final includedAttachmentFileNames = <String>[];
    final missingAttachmentFileNames = <String>[];
    final eventIds = events.map((event) => event.eventId).toList();

    _addBytesToArchive(
      archiveEntries,
      'timeline_report.pdf',
      pdfBytes,
      usedPaths,
    );

    final eventRecords = events.map((event) => event.toJson()).toList();
    _addBytesToArchive(
      archiveEntries,
      'data/events.json',
      utf8.encode(JsonEncoder.withIndent('  ').convert(eventRecords)),
      usedPaths,
    );

    int includedAttachmentCount = 0;
    for (final event in events) {
      final attachments = await _fetchAttachments(event.eventId.toString());
      for (final attachment in attachments) {
        final resolved = await _resolveAttachmentBytes(attachment);
        if (resolved == null) {
          missingAttachmentFileNames.add(attachment.fileName);
          debugPrint('ZIP export: missing attachment ${attachment.fileName}');
          continue;
        }

        final archivePath = _timelineAttachmentArchivePath(event, attachment);
        final uniqueArchivePath = _uniqueArchivePath(archivePath, usedPaths);
        _addBytesToArchive(
          archiveEntries,
          uniqueArchivePath,
          resolved,
          usedPaths,
        );
        includedAttachmentFileNames.add(uniqueArchivePath);
        includedAttachmentCount += 1;
      }
    }

    final metadata = <String, Object?>{
      'exportType': 'timeline',
      'exportDateTime': DateTime.now().toIso8601String(),
      'selectedDateRange': {
        'start': filterStartDate?.toIso8601String(),
        'end': filterEndDate?.toIso8601String(),
      },
      'eventCount': events.length,
      'eventRecordCount': eventRecords.length,
      'attachmentCount': includedAttachmentCount,
      'eventIds': eventIds,
      'includedAttachmentFileNames': includedAttachmentFileNames,
      'missingAttachmentFileNames': missingAttachmentFileNames,
    };
    _addBytesToArchive(
      archiveEntries,
      'metadata/export_info.json',
      utf8.encode(JsonEncoder.withIndent('  ').convert(metadata)),
      usedPaths,
    );

    final zipBytes = _zipArchiveService.createZip(archiveEntries);
    final fileName = _buildTimelineZipFileName(
      filterStartDate: filterStartDate,
      filterEndDate: filterEndDate,
    );
    final saveLocation = await _saveZip(zipBytes, fileName);

    return ExportResult(
      fileName: fileName,
      saveLocation: saveLocation,
      bytes: zipBytes,
    );
  }

  Future<List<EventNoteModel>> _fetchNotes(int eventId) async {
    return _detailRepository.getNotesByEventId(eventId);
  }

  Future<List<EventAttachment>> _fetchAttachments(String eventId) async {
    return _attachmentRepository.getAttachmentsForEvent(eventId);
  }

  Future<Uint8List?> _resolveAttachmentBytes(EventAttachment attachment) async {
    try {
      final resolvedPath = await _localFileService.resolvePath(attachment);
      if (resolvedPath == null || resolvedPath.isEmpty) {
        return null;
      }

      final file = File(resolvedPath);
      if (!await file.exists()) {
        return null;
      }
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  void _addBytesToArchive(
    List<ExportArchiveEntry> archiveEntries,
    String archivePath,
    List<int> bytes,
    Set<String> usedPaths,
  ) {
    final uniquePath = _uniqueArchivePath(archivePath, usedPaths);
    archiveEntries.add(ExportArchiveEntry(path: uniquePath, bytes: bytes));
    usedPaths.add(uniquePath);
  }

  String _eventAttachmentArchivePath(EventAttachment attachment) {
    final folder = _attachmentFolder(attachment);
    return p.posix.join(folder, _sanitizeArchiveFileName(attachment.fileName));
  }

  String _timelineAttachmentArchivePath(
    EventModel event,
    EventAttachment attachment,
  ) {
    final folder = _attachmentFolder(attachment);
    return p.posix.join(
      'events',
      event.eventId.toString(),
      folder,
      _sanitizeArchiveFileName(attachment.fileName),
    );
  }

  String _attachmentFolder(EventAttachment attachment) {
    if (attachment.isPreviewable) {
      return 'images';
    }
    if (attachment.isVideo) {
      return 'videos';
    }
    return 'files';
  }

  String _sanitizeArchiveFileName(String fileName) {
    final extension = p.extension(fileName);
    final baseName = p.basenameWithoutExtension(fileName);
    final sanitizedBase = baseName
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final sanitizedExtension = extension.isEmpty
        ? ''
        : extension.replaceAll(RegExp(r'[^A-Za-z0-9.]+'), '');
    final safeBase = sanitizedBase.isEmpty ? 'file' : sanitizedBase;
    return '$safeBase$sanitizedExtension';
  }

  String _uniqueArchivePath(String archivePath, Set<String> usedPaths) {
    if (!usedPaths.contains(archivePath)) {
      return archivePath;
    }

    final directory = p.posix.dirname(archivePath);
    final extension = p.posix.extension(archivePath);
    final baseName = p.posix.basenameWithoutExtension(archivePath);

    var index = 2;
    while (true) {
      final candidate = p.posix.join(directory, '${baseName}_$index$extension');
      if (!usedPaths.contains(candidate)) {
        return candidate;
      }
      index += 1;
    }
  }

  String _buildEventZipFileName(EventModel event) {
    final timestamp = DateTime.now();
    final suffix =
        '${timestamp.year}${_twoDigits(timestamp.month)}${_twoDigits(timestamp.day)}_${_twoDigits(timestamp.hour)}${_twoDigits(timestamp.minute)}';
    return 'event_export_${event.eventId}_$suffix';
  }

  String _buildTimelineZipFileName({
    DateTime? filterStartDate,
    DateTime? filterEndDate,
  }) {
    final start = filterStartDate == null
        ? 'all_events'
        : _compactDate(filterStartDate);
    final end = filterEndDate == null
        ? 'all_events'
        : _compactDate(filterEndDate);
    return 'timeline_export_${start}_to_${end}';
  }

  String _compactDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)}';
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  Future<String> _saveZip(Uint8List bytes, String fileName) async {
    return _fileSaveService.saveZip(bytes, fileName);
  }
}

class _ResolvedAttachment {
  final EventAttachment attachment;
  final String reference;
  final Uint8List? bytes;
  final Uint8List? previewBytes;
  final String? error;

  const _ResolvedAttachment({
    required this.attachment,
    required this.reference,
    this.bytes,
    this.previewBytes,
    this.error,
  });
}

class _TimelineEventDetail {
  final List<EventNoteModel> notes;
  final List<EventAttachment> attachments;

  const _TimelineEventDetail({required this.notes, required this.attachments});
}
