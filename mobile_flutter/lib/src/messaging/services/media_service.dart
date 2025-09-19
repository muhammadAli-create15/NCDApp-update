import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart'; // For decodeImageFromList
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class MediaService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _baseUrl; // Base URL for API requests
  final ImagePicker _imagePicker = ImagePicker();

  // Constructor
  MediaService({
    String baseUrl = 'https://api.example.com', // Replace with actual API URL
  }) : _baseUrl = baseUrl;

  // Pick image from gallery
  Future<File?> pickImageFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );

    if (image == null) return null;
    return File(image.path);
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );

    if (image == null) return null;
    return File(image.path);
  }

  // Pick video from gallery
  Future<File?> pickVideoFromGallery({
    Duration? maxDuration,
  }) async {
    final XFile? video = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: maxDuration,
    );

    if (video == null) return null;
    return File(video.path);
  }

  // Pick video from camera
  Future<File?> pickVideoFromCamera({
    Duration? maxDuration,
  }) async {
    final XFile? video = await _imagePicker.pickVideo(
      source: ImageSource.camera,
      maxDuration: maxDuration,
    );

    if (video == null) return null;
    return File(video.path);
  }

  // Upload file to server
  Future<String?> uploadFile(File file, {String? chatId}) async {
    try {
      // Get the file extension
      final fileExtension = path.extension(file.path);
      
      // Create a unique file name
      final fileName = '${const Uuid().v4()}$fileExtension';
      
      // Define bucket path
      final String bucketPath = chatId != null 
          ? 'chats/$chatId/$fileName' 
          : 'media/$fileName';

      // For Supabase storage
      final response = await _supabase.storage
          .from('ncd-app-media')
          .upload(bucketPath, file);
      
      // Get the public URL
      final fileUrl = _supabase.storage
          .from('ncd-app-media')
          .getPublicUrl(bucketPath);
      
      return fileUrl;
    } catch (e) {
      debugPrint('MediaService: Error uploading file: $e');
      
      // For demo purposes, return a placeholder URL
      return 'https://via.placeholder.com/300x200';
    }
  }

  // Get media dimensions
  Future<Map<String, dynamic>> getImageDimensions(File file) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      final image = await decodeImageFromList(bytes);
      return {
        'width': image.width,
        'height': image.height,
      };
    } catch (e) {
      debugPrint('MediaService: Error getting image dimensions: $e');
      return {
        'width': 300,
        'height': 200,
      };
    }
  }

  // Download file from URL
  Future<File?> downloadFile(String url, String localPath) async {
    try {
      final response = await http.get(Uri.parse(url));
      final file = File(localPath);
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e) {
      debugPrint('MediaService: Error downloading file: $e');
      return null;
    }
  }

  // Delete file from server
  Future<bool> deleteFile(String url) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(url);
      final path = uri.pathSegments.join('/');
      
      await _supabase.storage.from('ncd-app-media').remove([path]);
      return true;
    } catch (e) {
      debugPrint('MediaService: Error deleting file: $e');
      return false;
    }
  }
}