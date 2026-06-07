import 'attachment_type.dart';

class EventAttachment {
  final String id;
  final String eventId;
  final String fileName;
  final String? localPath;
  final String? assetPath;
  final String? thumbnailPath;
  final AttachmentType type;
  final int? sizeBytes;
  final String? mimeType;
  final DateTime? createdAt;

  const EventAttachment({
    required this.id,
    required this.eventId,
    required this.fileName,
    this.localPath,
    this.assetPath,
    this.thumbnailPath,
    required this.type,
    this.sizeBytes,
    this.mimeType,
    this.createdAt,
  });

  String? get previewPath => thumbnailPath ?? localPath ?? assetPath;

  String get fileExtension {
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex == -1 || lastDotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(lastDotIndex + 1).toLowerCase();
  }

  /// Format file size for display
  String get formattedSize {
    if (sizeBytes == null) return 'Unknown';
    if (sizeBytes! < 1024) return '${sizeBytes!} B';
    if (sizeBytes! < 1024 * 1024) {
      return '${(sizeBytes! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Check if attachment can be previewed inline
  bool get isPreviewable => type == AttachmentType.image;

  /// Check if attachment is a video
  bool get isVideo => type == AttachmentType.video;

  /// Check if attachment is a non-media file
  bool get isFile =>
      type == AttachmentType.pdf ||
      type == AttachmentType.csv ||
      type == AttachmentType.docx ||
      type == AttachmentType.xlsx ||
      type == AttachmentType.other;

  bool get hasLocalPath => localPath != null && localPath!.isNotEmpty;

  bool get hasAssetPath => assetPath != null && assetPath!.isNotEmpty;

  factory EventAttachment.fromMap(Map<String, dynamic> map) {
    final fileExtension = (map['fileName'] ?? '').toString().split('.').last;

    // Try to parse type from index, fallback to file extension
    AttachmentType attachmentType;
    if (map['type'] != null && map['type'] is int) {
      try {
        final typeIndex = map['type'] as int;
        if (typeIndex >= 0 && typeIndex < AttachmentType.values.length) {
          attachmentType = AttachmentType.values[typeIndex];
        } else {
          attachmentType = parseAttachmentTypeFromExtension(fileExtension);
        }
      } catch (e) {
        attachmentType = parseAttachmentTypeFromExtension(fileExtension);
      }
    } else {
      attachmentType = parseAttachmentTypeFromExtension(fileExtension);
    }

    return EventAttachment(
      id: (map['id'] ?? '') as String,
      eventId: (map['eventId'] ?? '') as String,
      fileName: (map['fileName'] ?? '') as String,
      localPath: map['localPath'] as String? ?? map['fileUrl'] as String?,
      assetPath: map['assetPath'] as String?,
      thumbnailPath:
          map['thumbnailPath'] as String? ?? map['thumbnailUrl'] as String?,
      type: attachmentType,
      sizeBytes: map['sizeBytes'] as int?,
      mimeType: map['mimeType'] as String?,
      createdAt: map['createdAt'] is String
          ? DateTime.tryParse(map['createdAt'] as String)
          : (map['createdAt'] as DateTime? ??
                (map['uploadedAt'] is String
                    ? DateTime.tryParse(map['uploadedAt'] as String)
                    : map['uploadedAt'] as DateTime?)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'fileName': fileName,
      'localPath': localPath,
      'assetPath': assetPath,
      'thumbnailPath': thumbnailPath,
      'type': type.index,
      'sizeBytes': sizeBytes,
      'mimeType': mimeType,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
