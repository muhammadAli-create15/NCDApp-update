import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';

class AttachmentService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Constants for storage buckets
  static const String MESSAGE_ATTACHMENTS_BUCKET = 'message_attachments';
  
  // Upload a message attachment
  Future<Map<String, dynamic>> uploadMessageAttachment({
    required File file,
    required String chatId,
    required String messageId,
  }) async {
    try {
      final String extension = path.extension(file.path);
      final String fileName = '${const Uuid().v4()}$extension';
      
      // Define the path in the storage
      // Using chatId/messageId/filename format for better organization
      final String filePath = '$chatId/$messageId/$fileName';
      
      // Upload the file to Supabase Storage
      await _supabase.storage
          .from(MESSAGE_ATTACHMENTS_BUCKET)
          .upload(filePath, file);
      
      // Get the public URL
      final String fileUrl = _supabase.storage
          .from(MESSAGE_ATTACHMENTS_BUCKET)
          .getPublicUrl(filePath);
      
      // Get file size
      final int fileSize = await file.length();
      
      // Get file type and format metadata
      final String mimeType = _getMimeType(extension);
      final MessageType messageType = _getMessageTypeFromMime(mimeType);
      
      return {
        'url': fileUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'mimeType': mimeType,
        'type': messageType,
        'metadata': {
          'size': fileSize,
          'name': fileName,
          'extension': extension,
          'path': filePath,
        }
      };
    } catch (e) {
      debugPrint('AttachmentService: Error uploading attachment: $e');
      rethrow;
    }
  }
  
  // Delete a message attachment
  Future<void> deleteMessageAttachment(String filePath) async {
    try {
      await _supabase.storage
          .from(MESSAGE_ATTACHMENTS_BUCKET)
          .remove([filePath]);
    } catch (e) {
      debugPrint('AttachmentService: Error deleting attachment: $e');
      rethrow;
    }
  }
  
  // Get mime type from file extension
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
      case '.docx':
        return 'application/msword';
      case '.mp4':
        return 'video/mp4';
      case '.mp3':
        return 'audio/mp3';
      default:
        return 'application/octet-stream';
    }
  }
  
  // Get message type from mime type
  MessageType _getMessageTypeFromMime(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return MessageType.image;
    } else if (mimeType.startsWith('video/')) {
      return MessageType.video;
    } else if (mimeType.startsWith('audio/')) {
      return MessageType.audio;
    } else {
      return MessageType.file;
    }
  }
}