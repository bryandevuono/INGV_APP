import 'package:docx_file_viewer/docx_file_viewer.dart';
import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/attachment_type.dart';
import 'package:ingv_app/data/models/event_attachment.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../data/repositories/document_view_repository.dart';
import '../view_models/document_viewer_view_model.dart';

class DocumentViewerDialog extends StatefulWidget {
  final EventAttachment attachment;
  final String filePath;
  final Future<void> Function()? onOpenExternally;

  const DocumentViewerDialog({
    super.key,
    required this.attachment,
    required this.filePath,
    this.onOpenExternally,
  });

  @override
  State<DocumentViewerDialog> createState() => _DocumentViewerDialogState();
}

class _DocumentViewerDialogState extends State<DocumentViewerDialog> {
  Object? _docxError;
  late final DocumentViewerViewModel _documentViewModel;

  bool get _isPdf => widget.attachment.type == AttachmentType.pdf;
  bool get _isDocx => widget.attachment.type == AttachmentType.docx;

  @override
  void initState() {
    super.initState();

    _documentViewModel = DocumentViewerViewModel(
      documentRepository: DocumentViewRepository(),
      filePath: widget.filePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        color: Colors.grey.shade100,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(
            _isPdf ? Icons.picture_as_pdf : Icons.description,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.attachment.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.attachment.formattedSize,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          if (widget.onOpenExternally != null)
            IconButton(
              tooltip: 'Open externally',
              icon: const Icon(
                Icons.open_in_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () async {
                await widget.onOpenExternally!.call();
              },
            ),
          if (_isPdf) ...[
            IconButton(
              tooltip: 'Zoom In',
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              onPressed: () => _documentViewModel.handleZoomIn(),
            ),
            IconButton(
              tooltip: 'Zoom Out',
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Colors.white,
              ),
              onPressed: () => _documentViewModel.handleZoomOut(),
            ),
          ],
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isPdf) {
      return PdfViewer.file(
        widget.filePath,
        controller: _documentViewModel.pdfController,
        params: PdfViewerParams(
          maxScale: 8.0,
          viewerOverlayBuilder: (context, size, handle) => [
            PdfViewerScrollThumb(
              controller: _documentViewModel.pdfController,
              orientation: ScrollbarOrientation.right,
            ),
          ],
        ),
      );
    }

    if (_isDocx) {
      return Container(
        color: Colors.white,
        child: Stack(
          children: [
            Positioned.fill(
              child: DocxView(
                path: widget.filePath,
                config: _documentViewModel.docxConfig,
                onError: (error) {
                  if (!mounted) return;
                  setState(() {
                    _docxError = error;
                  });
                },
              ),
            ),
            if (_docxError != null)
              Positioned.fill(
                child: _buildErrorState(
                  'This document could not be displayed in-app.',
                ),
              ),
          ],
        ),
      );
    }

    return _buildErrorState(
      'This file type is not supported for in-app viewing.',
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.grey.shade700,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade800),
                ),
                if (widget.onOpenExternally != null) ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await widget.onOpenExternally!.call();
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Externally'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
