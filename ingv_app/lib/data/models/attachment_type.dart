enum AttachmentType { image, video, pdf, csv, docx, xlsx, other }

extension AttachmentTypeExtension on AttachmentType {
  String get displayName {
    switch (this) {
      case AttachmentType.image:
        return 'Image';
      case AttachmentType.video:
        return 'Video';
      case AttachmentType.pdf:
        return 'PDF Document';
      case AttachmentType.csv:
        return 'CSV Data';
      case AttachmentType.docx:
        return 'Word Document';
      case AttachmentType.xlsx:
        return 'Excel Spreadsheet';
      case AttachmentType.other:
        return 'File';
    }
  }
}

/// Parse attachment type from file extension
AttachmentType parseAttachmentTypeFromExtension(String extension) {
  final ext = extension.toLowerCase();
  switch (ext) {
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'webp':
      return AttachmentType.image;
    case 'mp4':
    case 'mov':
    case 'avi':
    case 'mkv':
    case 'webm':
      return AttachmentType.video;
    case 'pdf':
      return AttachmentType.pdf;
    case 'csv':
      return AttachmentType.csv;
    case 'docx':
      return AttachmentType.docx;
    case 'xlsx':
    case 'xls':
      return AttachmentType.xlsx;
    default:
      return AttachmentType.other;
  }
}
