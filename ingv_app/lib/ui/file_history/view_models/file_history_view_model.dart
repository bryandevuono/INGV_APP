import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/file_version.dart';
import 'package:ingv_app/data/repositories/attachment_repository.dart';

class DocumentMergeViewModel extends ChangeNotifier {
  List<FileVersion> _documentHistory = [];
  FileVersion? _leftVersion;
  FileVersion? _rightVersion;

  final LocalAttachmentRepository _attachmentRepository =
      LocalAttachmentRepository();
  bool _isSaving = false;

  List<FileVersion> get documentHistory => _documentHistory;
  FileVersion? get leftVersion => _leftVersion;
  FileVersion? get rightVersion => _rightVersion;
  bool get isSaving => _isSaving;

  void generateFileHistory() async {
    final versions = await _attachmentRepository.getFileHistoryFromAttachment(
      'mock_1',
    );

    _documentHistory = versions;

    for (var version in _documentHistory) {
      version.blocks = _parseStringToBlocks(version.content ?? '');
    }

    if (_documentHistory.isNotEmpty) {
      if (_documentHistory.length > 1) {
        _leftVersion = _documentHistory[_documentHistory.length - 2];
      } else {
        _leftVersion = _documentHistory[0];
      }

      _rightVersion = _documentHistory[_documentHistory.length - 1];
    }

    notifyListeners();
  }

  void updateSelectedVersion({
    required FileVersion targetVersion,
    required bool isLeftColumn,
  }) {
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
          blocks.add(
            TextBlock(
              id: 'sec_$sectionCounter',
              title: currentTitle,
              content: currentContent.toString().trim(),
            ),
          );
          sectionCounter++;
          currentContent.clear();
        }
        currentTitle = line.replaceFirst('##', '').trim();
      } else {
        currentContent.writeln(line);
      }
    }

    if (currentContent.isNotEmpty || blocks.isEmpty) {
      blocks.add(
        TextBlock(
          id: 'sec_$sectionCounter',
          title: currentTitle,
          content: currentContent.toString().trim(),
        ),
      );
    }

    return blocks;
  }

  void updateBlockSelection(String blockId, bool isLeft, bool selected) {
    FileVersion? targetVersion;
    if (isLeft) {
      targetVersion = _leftVersion;
    } else {
      targetVersion = _rightVersion;
    }

    FileVersion? opposingVersion;
    if (isLeft) {
      opposingVersion = _rightVersion;
    } else {
      opposingVersion = _leftVersion;
    }

    if (targetVersion != null) {
      try {
        targetVersion.blocks.firstWhere((b) => b.id == blockId).isSelected =
            selected;
        if (selected && opposingVersion != null) {
          opposingVersion.blocks.firstWhere((b) => b.id == blockId).isSelected =
              false;
        }
      } catch (_) {}
      notifyListeners();
    }
  }

  void selectAllForVersion(bool isLeft) {
    FileVersion? targetVersion;
    if (isLeft) {
      targetVersion = _leftVersion;
    } else {
      targetVersion = _rightVersion;
    }

    FileVersion? opposingVersion;
    if (isLeft) {
      opposingVersion = _rightVersion;
    } else {
      opposingVersion = _leftVersion;
    }

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
    if (_leftVersion == null || _rightVersion == null) return false;

    _isSaving = true;
    notifyListeners();

    final StringBuffer compiledMarkdown = StringBuffer();

    int maxBlocksCount;
    if (_leftVersion!.blocks.length > _rightVersion!.blocks.length) {
      maxBlocksCount = _leftVersion!.blocks.length;
    } else {
      maxBlocksCount = _rightVersion!.blocks.length;
    }

    for (int i = 0; i < maxBlocksCount; i++) {
      TextBlock? leftBlock;
      if (_leftVersion!.blocks.length > i) {
        leftBlock = _leftVersion!.blocks[i];
      } else {
        leftBlock = null;
      }

      TextBlock? rightBlock;
      if (_rightVersion!.blocks.length > i) {
        rightBlock = _rightVersion!.blocks[i];
      } else {
        rightBlock = null;
      }

      // Whch block is accepted?
      TextBlock? chosenBlock;
      if (leftBlock != null && leftBlock.isSelected) {
        chosenBlock = leftBlock;
      } else if (rightBlock != null && rightBlock.isSelected) {
        chosenBlock = rightBlock;
      } else {
        // Default Fallback if neither was actively accepted: use the newer version (right column)
        if (rightBlock != null) {
          chosenBlock = rightBlock;
        } else {
          chosenBlock = leftBlock;
        }
      }

      if (chosenBlock != null) {
        compiledMarkdown.writeln('## ${chosenBlock.title}');
        compiledMarkdown.writeln(chosenBlock.content);
        compiledMarkdown.writeln(); // spacing line
      }
    }

    // Pass the text
    await _attachmentRepository.saveMergedVersion(
      'mock_1',
      compiledMarkdown.toString().trim(),
    );

    _isSaving = false;
    notifyListeners();
    return true;
  }
}
