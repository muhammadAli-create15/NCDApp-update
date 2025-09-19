import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageHelper {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  // Constants for storage buckets
  static const String MESSAGE_ATTACHMENTS_BUCKET = 'message_attachments';
  static const String POST_ATTACHMENTS_BUCKET = 'post_attachments';
  
  // Create the required buckets in Supabase Storage if they don't exist
  static Future<void> initializeBuckets() async {
    try {
      // Get the list of buckets using the REST API
      final baseUrl = _supabase.rest.url;
      final response = await http.get(
        Uri.parse('$baseUrl/storage/buckets'),
        headers: {
          'Authorization': 'Bearer ${_supabase.auth.currentSession!.accessToken}',
          'apikey': _supabase.auth.currentSession!.accessToken,
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> buckets = json.decode(response.body);
        final bucketNames = buckets.map((b) => b['name'] as String).toList();
        
        // Create message attachments bucket if it doesn't exist
        if (!bucketNames.contains(MESSAGE_ATTACHMENTS_BUCKET)) {
          await _createBucket(MESSAGE_ATTACHMENTS_BUCKET, true);
        }
        
        // Create post attachments bucket if it doesn't exist
        if (!bucketNames.contains(POST_ATTACHMENTS_BUCKET)) {
          await _createBucket(POST_ATTACHMENTS_BUCKET, true);
        }
      }
    } catch (e) {
      debugPrint('Error initializing storage buckets: $e');
    }
  }
  
  // Create a new storage bucket
  static Future<void> _createBucket(String name, bool isPublic) async {
    try {
      final baseUrl = _supabase.rest.url;
      await http.post(
        Uri.parse('$baseUrl/storage/buckets'),
        headers: {
          'Authorization': 'Bearer ${_supabase.auth.currentSession!.accessToken}',
          'apikey': _supabase.auth.currentSession!.accessToken,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'public': isPublic,
        }),
      );
    } catch (e) {
      debugPrint('Error creating bucket $name: $e');
      rethrow;
    }
  }
  
  // Check if a bucket exists and create it if it doesn't
  static Future<void> ensureBucketExists(String name, {bool isPublic = true}) async {
    try {
      // Try to get bucket info
      final baseUrl = _supabase.rest.url;
      final response = await http.get(
        Uri.parse('$baseUrl/storage/buckets/$name'),
        headers: {
          'Authorization': 'Bearer ${_supabase.auth.currentSession!.accessToken}',
          'apikey': _supabase.auth.currentSession!.accessToken,
        },
      );
      
      // If bucket doesn't exist (404), create it
      if (response.statusCode == 404) {
        await _createBucket(name, isPublic);
      }
    } catch (e) {
      debugPrint('Error checking bucket $name: $e');
    }
  }
}