import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/chat_message.dart';

class MessageAttachmentView extends StatelessWidget {
  final ChatMessage message;
  
  const MessageAttachmentView({
    Key? key,
    required this.message,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return _buildImageAttachment();
      case MessageType.video:
        return _buildVideoAttachment();
      case MessageType.file:
        return _buildFileAttachment();
      case MessageType.audio:
        return _buildAudioAttachment();
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildImageAttachment() {
    return GestureDetector(
      onTap: () {
        // TODO: Implement full-screen image view
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: message.content,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.error),
          fit: BoxFit.cover,
          width: 200,
          height: 150,
        ),
      ),
    );
  }
  
  Widget _buildVideoAttachment() {
    // TODO: Implement video player
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      width: 200,
      height: 150,
      child: const Center(
        child: Icon(Icons.play_circle_filled, size: 48, color: Colors.white),
      ),
    );
  }
  
  Widget _buildFileAttachment() {
    final fileName = message.metadata?['name'] as String? ?? 'File';
    final fileSize = message.metadata?['size'] as int? ?? 0;
    final formattedSize = _formatFileSize(fileSize);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file, size: 32),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(formattedSize),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.download),
        ],
      ),
    );
  }
  
  Widget _buildAudioAttachment() {
    // TODO: Implement audio player
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.audiotrack, size: 32),
          const SizedBox(width: 12),
          const Icon(Icons.play_arrow, size: 32),
          Slider(
            value: 0,
            onChanged: (value) {},
            min: 0,
            max: 100,
          ),
          const Text('0:00'),
        ],
      ),
    );
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
      return '$mb MB';
    } else {
      final gb = (bytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
      return '$gb GB';
    }
  }
}