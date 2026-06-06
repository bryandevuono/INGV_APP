import 'dart:io';
import 'package:file_picker/file_picker.dart';

abstract class IFilePickerService {
  Future<File?> pickImage();
  Future<File?> pickVideo();
  Future<File?> pickFile();
  Future<List<File>> pickMultipleFiles();
}

class FilePickerService implements IFilePickerService {
  @override
  Future<File?> pickImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        return File(result.files.first.path!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<File?> pickVideo() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        return File(result.files.first.path!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<File?> pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        return File(result.files.first.path!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<File>> pickMultipleFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        return result.files.map((f) => File(f.path!)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
