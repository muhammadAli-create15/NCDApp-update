import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/media_upload_provider.dart';
import '../services/chat_service.dart';
import '../services/chat_provider.dart';

class AttachmentHandler {
  final BuildContext context;
  final String chatId;
  
  AttachmentHandler(this.context, this.chatId);
  
  // Get media upload provider
  MediaUploadProvider get _mediaUploadProvider => 
      Provider.of<MediaUploadProvider>(context, listen: false);
  
  // Get chat service
  ChatService get _chatService => 
      Provider.of<ChatProvider>(context, listen: false).chatService;
  
  // Pick and send image
  Future<void> pickAndSendImage({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      await _uploadAndSendAttachment(file);
    }
  }
  
  // Pick and send video
  Future<void> pickAndSendVideo({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickVideo(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    
    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      await _uploadAndSendAttachment(file);
    }
  }
  
  // Upload and send attachment
  Future<void> _uploadAndSendAttachment(File file) async {
    try {
      // Create placeholder message content
      const placeholderContent = 'Uploading attachment...';
      
      // Send placeholder message
      final message = await _chatService.sendMessage(
        chatId: chatId,
        content: placeholderContent,
        type: MessageType.text,
      );
      
      // Upload attachment
      final result = await _mediaUploadProvider.uploadMessageAttachment(
        file: file,
        chatId: chatId,
        messageId: message.id,
      );
      
      // Update message with attachment info
      final updatedMessage = message.copyWith(
        content: result['url'],
        type: result['type'],
        metadata: result['metadata'],
      );
      
      // Update the message in the chat
      await _chatService.updateMessage(updatedMessage);
      
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload attachment: $e')),
      );
    }
  }
  
  // Show attachment options dialog
  Future<void> showAttachmentOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Photo from gallery'),
              onTap: () {
                Navigator.pop(context);
                pickAndSendImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                pickAndSendImage(fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Video from gallery'),
              onTap: () {
                Navigator.pop(context);
                pickAndSendVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record a video'),
              onTap: () {
                Navigator.pop(context);
                pickAndSendVideo(fromCamera: true);
              },
            ),
          ],
        ),
      ),
    );
  }
}