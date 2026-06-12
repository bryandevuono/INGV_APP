import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:docx_file_viewer/docx_file_viewer.dart';
import 'package:ingv_app/data/repositories/document_viewer_interface.dart';

class DocumentViewerViewModel extends ChangeNotifier {
  final IDocumentViewerRepository documentRepository;
  String filePath;

  DocumentViewerViewModel({
    required this.documentRepository,
    required this.filePath,
  });

  PdfViewerController get pdfController => documentRepository.nativeController;
  DocxViewConfig get docxConfig => documentRepository.docxConfig;

  void setFilePath(String newPath) {
    filePath = newPath;
    notifyListeners();
  }
  
  void handleZoomIn() => documentRepository.zoomIn();
  void handleZoomOut() => documentRepository.zoomOut();
}