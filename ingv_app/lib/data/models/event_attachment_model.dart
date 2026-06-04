class EventAttachmentModel {
  final int attachmentId;
  final String fileName;
  final int fileSizeBytes;
  final String fileType; // 'csv', 'pdf', etc.
  final DateTime uploadedAt;

  EventAttachmentModel({
    required this.attachmentId,
    required this.fileName,
    required this.fileSizeBytes,
    required this.fileType,
    required this.uploadedAt,
  });

  String get fileSizeDisplay {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024)
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory EventAttachmentModel.fromMap(Map<String, dynamic> map) {
    return EventAttachmentModel(
      attachmentId: map['attachment_id'] as int? ?? 0,
      fileName: map['file_name'] as String? ?? '',
      fileSizeBytes: map['file_size_bytes'] as int? ?? 0,
      fileType: map['file_type'] as String? ?? 'unknown',
      uploadedAt: map['uploaded_at'] is String
          ? DateTime.parse(map['uploaded_at'] as String)
          : (map['uploaded_at'] as DateTime? ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'attachment_id': attachmentId,
      'file_name': fileName,
      'file_size_bytes': fileSizeBytes,
      'file_type': fileType,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}
