class TextBlock {
  final String id;
  final String title;
  final String content;
  bool isSelected;

  TextBlock({
    required this.id,
    required this.title,
    required this.content,
    this.isSelected = false,
  });
}

class FileVersion {
  final String versionId;
  final String versionName;
  final String metaInfo;
  final String subtitle;
  String? content;
  List<TextBlock> blocks;

  FileVersion({
    required this.versionId,
    required this.versionName,
    required this.metaInfo,
    required this.subtitle,
    required this.blocks,
  });
}
