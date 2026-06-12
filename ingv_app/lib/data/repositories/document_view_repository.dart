import 'package:docx_file_viewer/docx_file_viewer.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import 'document_viewer_interface.dart';

class DocumentViewRepository implements IDocumentViewerRepository {
  final pdfrx.PdfViewerController _innerController =
      pdfrx.PdfViewerController();

  @override
  pdfrx.PdfViewerController get nativeController => _innerController;

  @override
  DocxViewConfig get docxConfig => DocxViewConfig(
    enableSearch: false,
    enableZoom: false, // Disables accidental scroll-zoom
    backgroundColor: Colors.white,
    theme: DocxViewTheme.light(),
  );

  @override
  void zoomIn() {
    _innerController.zoomUp();
  }

  @override
  void zoomOut() {
    _innerController.zoomDown();
  }
}
