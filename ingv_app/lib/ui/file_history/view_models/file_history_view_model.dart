import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/file_version.dart';
import 'package:ingv_app/data/repositories/attachment_repository.dart';

const String masterTemplateFile = '''
## Recent Increase
Seismic tremor activity remains steady but fluctuating ambient signatures.

## Thermal Matrix
No additional observations recorded for this sub-block sequence.
''';

class DocumentMergeViewModel extends ChangeNotifier {
  List<FileVersion> _documentHistory = [];
  FileVersion? _leftVersion;
  FileVersion? _rightVersion;
  LocalAttachmentRepository? _attachmentRepository;
  bool _isSaving = false;

  List<FileVersion> get documentHistory => _documentHistory;
  FileVersion? get leftVersion => _leftVersion;
  FileVersion? get rightVersion => _rightVersion;
  bool get isSaving => _isSaving;

  void generateFileHistory() async {
    _attachmentRepository = LocalAttachmentRepository();
    Future<List<FileVersion>> fileVersions = _attachmentRepository!.getFileHistoryFromAttachment();
    for (int i = 0; i < (await fileVersions).length; i++) {
      FileVersion version = (await fileVersions)[i];
      _documentHistory.add(version);
      (await fileVersions)[i].blocks = _parseStringToBlocks((await fileVersions)[i].content ?? '');
    }

    _leftVersion = _documentHistory[1];
    _rightVersion = _documentHistory[0];
    
    notifyListeners();
  }

  void updateSelectedVersion({required FileVersion targetVersion, required bool isLeftColumn}) {
    if (isLeftColumn) {
      _leftVersion = targetVersion;
    } else {
      _rightVersion = targetVersion;
    }
    notifyListeners();
  }

  List<TextBlock> _parseStringToBlocks(String rawText) {
    List<TextBlock> blocks = [];
    List<String> lines = rawText.split('\n');
    String currentTitle = 'General';
    StringBuffer currentContent = StringBuffer();
    int sectionCounter = 1;

    for (String line in lines) {
      if (line.trim().startsWith('##')) {
        if (currentContent.isNotEmpty) {
          blocks.add(TextBlock(
            id: 'sec_$sectionCounter', 
            title: currentTitle,
            content: currentContent.toString().trim(),
          ));
          sectionCounter++;
          currentContent.clear();
        }
        currentTitle = line.replaceFirst('##', '').trim();
      } else {
        currentContent.writeln(line);
      }
    }

    if (currentContent.isNotEmpty) {
      blocks.add(TextBlock(
        id: 'sec_$sectionCounter',
        title: currentTitle,
        content: currentContent.toString().trim(),
      ));
    }

    return blocks;
  }

  void updateBlockSelection(String blockId, bool isLeft, bool selected) {
    final targetVersion = isLeft ? _leftVersion : _rightVersion;
    final opposingVersion = isLeft ? _rightVersion : _leftVersion;

    if (targetVersion != null) {
      targetVersion.blocks.firstWhere((b) => b.id == blockId).isSelected = selected;
      
      if (selected && opposingVersion != null) {
        try {
          opposingVersion.blocks.firstWhere((b) => b.id == blockId).isSelected = false;
        } catch (_) {} 
      }
      notifyListeners();
    }
  }

  void selectAllForVersion(bool isLeft) {
    final targetVersion = isLeft ? _leftVersion : _rightVersion;
    final opposingVersion = isLeft ? _rightVersion : _leftVersion;

    if (targetVersion != null) {
      for (var block in targetVersion.blocks) {
        block.isSelected = true;
      }
      if (opposingVersion != null) {
        for (var block in opposingVersion.blocks) {
          block.isSelected = false;
        }
      }
      notifyListeners();
    }
  }

  Future<bool> compileAndSaveChanges() async {
    _isSaving = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    _isSaving = false;
    notifyListeners();
    return true; 
  }
}