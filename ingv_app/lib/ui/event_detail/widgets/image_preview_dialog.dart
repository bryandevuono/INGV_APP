import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_attachment.dart';

class ImagePreviewDialog extends StatefulWidget {
  final EventAttachment attachment;

  const ImagePreviewDialog({super.key, required this.attachment});

  @override
  State<ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<ImagePreviewDialog> {
  @override
  Widget build(BuildContext context) {
    final imagePath = widget.attachment.localPath;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              child: widget.attachment.hasAssetPath
                  ? Image.asset(
                      widget.attachment.assetPath!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildErrorState();
                      },
                    )
                  : imagePath != null
                  ? Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildErrorState();
                      },
                    )
                  : _buildErrorState(),
            ),

            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black87,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.attachment.fileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.attachment.formattedSize,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.error_outline, color: Colors.white, size: 48),
          SizedBox(height: 16),
          Text(
            'Failed to load local image',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
