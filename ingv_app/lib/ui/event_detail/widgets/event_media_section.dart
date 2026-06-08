import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/attachment_type.dart';
import 'package:ingv_app/data/models/event_attachment.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
import 'package:ingv_app/ui/event_detail/widgets/document_viewer_dialog.dart';
import 'package:ingv_app/ui/event_detail/widgets/image_preview_dialog.dart';
import 'package:ingv_app/ui/event_detail/widgets/video_player_dialog.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class EventMediaSection extends StatelessWidget {
  final EventDetailViewModel viewModel;

  const EventMediaSection({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Media & Attachments',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 12),
          if (viewModel.errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                viewModel.errorMessage!,
                style: TextStyle(fontSize: 11, color: Colors.red.shade700),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (viewModel.imageAttachments.isNotEmpty) ...[
            _SectionTitle(label: 'Images'),
            const SizedBox(height: 8),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: viewModel.imageAttachments.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final attachment = viewModel.imageAttachments[index];
                  return _MediaTile(
                    attachment: attachment,
                    overlayIcon: null,
                    onTap: () {
                      viewModel.selectAttachment(attachment);
                      showDialog(
                        context: context,
                        builder: (_) =>
                            ImagePreviewDialog(attachment: attachment),
                      ).then((_) => viewModel.selectAttachment(null));
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (viewModel.videoAttachments.isNotEmpty) ...[
            _SectionTitle(label: 'Videos'),
            const SizedBox(height: 8),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: viewModel.videoAttachments.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final attachment = viewModel.videoAttachments[index];
                  return _MediaTile(
                    attachment: attachment,
                    overlayIcon: Icons.play_circle_fill,
                    onTap: () {
                      viewModel.selectAttachment(attachment);
                      showDialog(
                        context: context,
                        builder: (_) => VideoPlayerDialog(
                          attachment: attachment,
                          onOpenExternally: () async {
                            await viewModel.openAttachment(attachment);
                          },
                        ),
                      ).then((_) => viewModel.selectAttachment(null));
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (viewModel.fileAttachments.isNotEmpty) ...[
            if (viewModel.imageAttachments.isNotEmpty ||
                viewModel.videoAttachments.isNotEmpty)
              Divider(color: Colors.grey.shade200, height: 12),
            const SizedBox(height: 8),
            _SectionTitle(label: 'Files'),
            const SizedBox(height: 8),
            Column(
              children: viewModel.fileAttachments.map((attachment) {
                final isBusy = viewModel.isAttachmentBusy(attachment.id);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _FileTile(
                    attachment: attachment,
                    isBusy: isBusy,
                    onOpen: () async {
                      if (attachment.type == AttachmentType.pdf ||
                          attachment.type == AttachmentType.docx) {
                        final filePath = await viewModel.resolveAttachmentPath(
                          attachment,
                        );
                        if (filePath == null || !context.mounted) {
                          return;
                        }

                        viewModel.selectAttachment(attachment);
                        await showDialog(
                          context: context,
                          builder: (_) => DocumentViewerDialog(
                            attachment: attachment,
                            filePath: filePath,
                            onOpenExternally: () async {
                              await viewModel.openAttachment(attachment);
                            },
                          ),
                        );
                        viewModel.selectAttachment(null);
                        return;
                      }

                      await viewModel.openAttachment(attachment);
                    },
                    onOpenExternally: () async {
                      await viewModel.openAttachment(attachment);
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (viewModel.attachments.isEmpty && !viewModel.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No local attachments',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
          if (viewModel.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => viewModel.pickAndAddMedia('image'),
                icon: const Icon(Icons.image, size: 16),
                label: const Text('Add Image'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade700,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => viewModel.pickAndAddMedia('video'),
                icon: const Icon(Icons.videocam, size: 16),
                label: const Text('Add Video'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade700,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => viewModel.pickAndAddAttachment(),
                icon: const Icon(Icons.attach_file, size: 16),
                label: const Text('Add File'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final EventAttachment attachment;
  final IconData? overlayIcon;
  final VoidCallback onTap;

  const _MediaTile({
    required this.attachment,
    required this.overlayIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 100,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildPreview(),
                  ),
                  if (overlayIcon != null)
                    Container(
                      color: Colors.black26,
                      child: Icon(overlayIcon, color: Colors.white, size: 34),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            attachment.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (attachment.type == AttachmentType.video) {
      return _InlineVideoThumbnail(attachment: attachment);
    }

    if (attachment.hasAssetPath) {
      return Image.asset(
        attachment.previewPath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    final previewPath = attachment.previewPath;
    if (previewPath == null) {
      return _placeholder();
    }

    return Image.file(
      File(previewPath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade300,
      child: Icon(
        attachment.type == AttachmentType.video ? Icons.videocam : Icons.image,
        color: Colors.grey.shade600,
      ),
    );
  }
}

class _InlineVideoThumbnail extends StatefulWidget {
  final EventAttachment attachment;

  const _InlineVideoThumbnail({required this.attachment});

  @override
  State<_InlineVideoThumbnail> createState() => _InlineVideoThumbnailState();
}

class _InlineVideoThumbnailState extends State<_InlineVideoThumbnail> {
  Player? _player;
  VideoController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    try {
      final player = Player();
      final controller = VideoController(player);
      _player = player;
      _controller = controller;

      if (widget.attachment.hasAssetPath) {
        await player.open(Media(widget.attachment.assetPath!), play: false);
      } else {
        await player.open(Media(widget.attachment.localPath!), play: false);
      }
      await player.seek(Duration.zero);

      if (!mounted) {
        await player.dispose();
        return;
      }
      setState(() {
        _ready = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _ready = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready && _controller != null) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: (_player?.state.width ?? 16).toDouble(),
          height: (_player?.state.height ?? 9).toDouble(),
          child: Video(controller: _controller!, fit: BoxFit.cover),
        ),
      );
    }

    return Container(
      color: Colors.grey.shade300,
      child: Icon(Icons.videocam, color: Colors.grey.shade600),
    );
  }
}

class _FileTile extends StatelessWidget {
  final EventAttachment attachment;
  final bool isBusy;
  final VoidCallback onOpen;
  final VoidCallback onOpenExternally;

  const _FileTile({
    required this.attachment,
    required this.isBusy,
    required this.onOpen,
    required this.onOpenExternally,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _getFileIcon(attachment.type);
    final color = _getFileColor(attachment.type);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${attachment.type.displayName}  •  ${attachment.formattedSize}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (isBusy)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(onPressed: onOpen, child: const Text('Open')),
                TextButton(
                  onPressed: onOpenExternally,
                  child: const Text('Open Externally'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  IconData _getFileIcon(AttachmentType type) {
    switch (type) {
      case AttachmentType.pdf:
        return Icons.picture_as_pdf;
      case AttachmentType.csv:
      case AttachmentType.xlsx:
        return Icons.table_chart;
      case AttachmentType.docx:
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(AttachmentType type) {
    switch (type) {
      case AttachmentType.pdf:
        return Colors.red;
      case AttachmentType.csv:
        return Colors.green;
      case AttachmentType.docx:
        return Colors.blue;
      case AttachmentType.xlsx:
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }
}
