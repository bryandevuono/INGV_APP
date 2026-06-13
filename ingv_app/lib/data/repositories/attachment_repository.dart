import 'dart:io';

import 'package:ingv_app/data/models/attachment_type.dart';
import 'package:ingv_app/data/models/event_attachment.dart';
import 'package:ingv_app/data/models/file_version.dart';
import 'attachment_repository_interface.dart';

class LocalAttachmentRepository implements IAttachmentRepository {
  LocalAttachmentRepository();

  static String _workspaceFile(String relativePath) {
    return Directory.current.uri.resolve(relativePath).toFilePath();
  }

  static final Map<String, List<EventAttachment>> _mockAttachments = {
    '1000': [
      EventAttachment(
        id: 'att_1',
        eventId: '1000',
        fileName: 'ash_plume.jpg',
        localPath: _workspaceFile(
          'test_container/test_container/mock-env/mock-data/pics/EMOV/20260322/1500/EMOV_20260322-155500.jpg',
        ),
        type: AttachmentType.image,
        sizeBytes: 245000,
        mimeType: 'image/jpeg',
        createdAt: DateTime(2026, 5, 14, 10, 30),
      ),
      EventAttachment(
        id: 'att_2',
        eventId: '1000',
        fileName: 'crater_view.jpg',
        localPath: _workspaceFile(
          'test_container/test_container/mock-env/mock-data/pics/EMOV/20260322/1500/EMOV_20260322-155000.jpg',
        ),
        type: AttachmentType.image,
        sizeBytes: 232000,
        mimeType: 'image/jpeg',
        createdAt: DateTime(2026, 5, 14, 11, 5),
      ),
      EventAttachment(
        id: 'att_3',
        eventId: '1000',
        fileName: 'thermal_image.jpg',
        localPath: _workspaceFile(
          'test_container/test_container/mock-env/mock-data/pics/EMOV/20260322/1500/EMOV_20260322-154500.jpg',
        ),
        type: AttachmentType.image,
        sizeBytes: 198000,
        mimeType: 'image/jpeg',
        createdAt: DateTime(2026, 5, 14, 12, 12),
      ),
      EventAttachment(
        id: 'att_4',
        eventId: '1000',
        fileName: 'eruption_overview.avi',
        localPath: _workspaceFile(
          'test_container/test_container/mock-env/mock-data/multimedia/avi/EMOV_20260322-155500.avi',
        ),
        thumbnailPath: _workspaceFile(
          'test_container/test_container/mock-env/mock-data/pics/EMOV/20260322/1500/EMOV_20260322-155500.jpg',
        ),
        type: AttachmentType.video,
        sizeBytes: 5200000,
        mimeType: 'video/x-msvideo',
        createdAt: DateTime(2026, 5, 14, 11, 15),
      ),
      EventAttachment(
        id: 'att_5',
        eventId: '1000',
        fileName: 'seismic_summary.pdf',
        localPath: _workspaceFile(
          'assets/local_attachments/seismic_summary.pdf',
        ),
        type: AttachmentType.pdf,
        sizeBytes: 1200000,
        mimeType: 'application/pdf',
        createdAt: DateTime(2026, 5, 14, 13, 45),
      ),
      EventAttachment(
        id: 'att_6',
        eventId: '1000',
        fileName: 'gas_readings_1210.csv',
        localPath: _workspaceFile(
          'assets/local_attachments/gas_readings_1210.csv',
        ),
        type: AttachmentType.csv,
        sizeBytes: 45000,
        mimeType: 'text/csv',
        createdAt: DateTime(2026, 5, 14, 14, 20),
      ),
      EventAttachment(
        id: 'att_7',
        eventId: '1000',
        fileName: 'ash_sample_lab.pdf',
        localPath: _workspaceFile(
          'assets/local_attachments/ash_sample_lab.pdf',
        ),
        type: AttachmentType.pdf,
        sizeBytes: 385000,
        mimeType: 'application/pdf',
        createdAt: DateTime(2026, 5, 14, 15, 0),
      ),
      EventAttachment(
        id: 'att_8',
        eventId: '1000',
        fileName: 'eruption_field_notes.txt',
        localPath: _workspaceFile(
          'assets/local_attachments/eruption_field_notes.txt',
        ),
        type: AttachmentType.other,
        sizeBytes: 2500,
        mimeType: 'text/plain',
        createdAt: DateTime(2026, 5, 14, 15, 30),
      ),
    ],
  };

  @override
  Future<List<EventAttachment>> getAttachmentsForEvent(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockAttachments[eventId] ?? [];
  }

  @override
  Future<EventAttachment?> getAttachmentById(String attachmentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    for (final attachments in _mockAttachments.values) {
      for (final attachment in attachments) {
        if (attachment.id == attachmentId) {
          return attachment;
        }
      }
    }
    return null;
  }

  @override
  Future<void> addAttachment(EventAttachment attachment) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mockAttachments.putIfAbsent(attachment.eventId, () => []);
    _mockAttachments[attachment.eventId]!.add(attachment);
  }

  @override
  Future<void> deleteAttachment(String attachmentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (final attachments in _mockAttachments.values) {
      attachments.removeWhere((a) => a.id == attachmentId);
    }
  }

  @override
  Future<void> updateAttachment(EventAttachment attachment) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final attachments = _mockAttachments[attachment.eventId];
    if (attachments != null) {
      final index = attachments.indexWhere((a) => a.id == attachment.id);
      if (index != -1) {
        attachments[index] = attachment;
      }
    }
  }

  @override
  Future<List<FileVersion>> getFileHistoryFromAttachment(
  ) async {
    final List<String> textHistory = 
    [
      """
      ## heading 1
      Content of version 1, line 1.
      Content of version 1, line 2.
      Content of version 1, line 3.
      Content of version 1, line 4.
      ## heading 2
      Content of version 2, line 1.
      Content of version 2, line 2.
      Content of version 2, line 3.
      Content of version 2, line 4.
      ## heading 3
      Content of version 3, line 1.
      Content of version 3, line 2.
      Content of version 3, line 3.
      Content of version 3, line 4 (changed).
      """,
      """
      ## heading 1
      Content of version 1, line 1.
      Content of version 1, line 2.
      Content of version 1, line 3.
      Content of version 1, line 4.
      ## heading 2
      Content of version 2, line 1.
      Content of version 2, line 2.
      Content of version 2, line 3.
      Content of version 2, line 4.
      """,
      """
      ## heading 1
      Content of version 1, line 1.
      Content of version 1, line 2.
      Content of version 1, line 3.
      Content of version 1, line 4 (changed).
      ## heading 2
      Content of version 2, line 1.
      Content of version 2, line 2.
      Content of version 2, line 3.
      Content of version 2, line 4.
      """
    ];

    List<FileVersion> fileVersions = [];
    for (int i = 0; i < textHistory.length; i++) {
      FileVersion version = FileVersion(
        versionId: 'v${i + 1}',
        versionName: 'Version ${i + 1}',
        metaInfo: 'Meta info for version ${i + 1}',
        subtitle: 'Subtitle for version ${i + 1}',
        blocks: [],
      );
      version.content = textHistory[i];
      fileVersions.add(version);
    }
    return fileVersions;
  }
}
