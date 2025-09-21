import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageExamples {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> uploadFileToBucket(File file, String bucketName, String destPath) async {
    try {
      final res = await _supabase.storage.from(bucketName).upload(destPath, file);
      final publicUrl = _supabase.storage.from(bucketName).getPublicUrl(destPath);
      return publicUrl;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteFileFromBucket(String bucketName, String path) async {
    try {
      await _supabase.storage.from(bucketName).remove([path]);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// For private buckets, get a signed URL valid for [expiresIn] seconds.
  Future<String?> getSignedUrl(String bucketName, String path, {int expiresIn = 3600}) async {
    try {
      final res = await _supabase.storage.from(bucketName).createSignedUrl(path, expiresIn);
      return res; // createSignedUrl returns Map depending on SDK version; check docs
    } catch (e) {
      rethrow;
    }
  }
}
