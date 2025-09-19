import 'dart:io';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'attachment_service.dart';

class MediaUploadProvider extends ChangeNotifier {
  final MediaService _mediaService;
  final AttachmentService _attachmentService = AttachmentService();
  
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  
  MediaUploadProvider({
    required MediaService mediaService,
  }) : _mediaService = mediaService;
  
  // Getters
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  MediaService get mediaService => _mediaService;
  AttachmentService get attachmentService => _attachmentService;
  
  // Update upload progress
  void updateProgress(double progress) {
    _uploadProgress = progress;
    notifyListeners();
  }
  
  // Start upload
  void startUpload() {
    _isUploading = true;
    _uploadProgress = 0.0;
    notifyListeners();
  }
  
  // Complete upload
  void completeUpload() {
    _isUploading = false;
    _uploadProgress = 1.0;
    notifyListeners();
  }
  
  // Upload failed
  void failUpload() {
    _isUploading = false;
    notifyListeners();
  }
  
  // Upload a message attachment
  Future<Map<String, dynamic>> uploadMessageAttachment({
    required File file,
    required String chatId,
    required String messageId,
  }) async {
    try {
      startUpload();
      
      final result = await _attachmentService.uploadMessageAttachment(
        file: file,
        chatId: chatId,
        messageId: messageId,
      );
      
      completeUpload();
      return result;
    } catch (e) {
      failUpload();
      rethrow;
    }
  }
}