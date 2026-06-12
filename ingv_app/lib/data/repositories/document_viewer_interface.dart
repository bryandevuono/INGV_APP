import 'package:docx_file_viewer/docx_file_viewer.dart';
import 'package:pdfrx/pdfrx.dart';

abstract interface class IDocumentViewerRepository {
  PdfViewerController get nativeController;
  
  DocxViewConfig get docxConfig;
  
  void zoomIn();
  void zoomOut();
}