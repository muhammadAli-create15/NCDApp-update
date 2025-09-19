import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../models/educational_content.dart';

/// Repository class for managing educational content storage and retrieval
class EducationContentRepository {
  // Keys for shared preferences
  static const String _contentCacheKey = 'education_content_cache';
  static const String _contentCacheTimestampKey = 'education_content_cache_timestamp';
  static const String _savedContentKey = 'saved_education_content';
  static const String _readContentKey = 'read_education_content';
  
  // Remote content URL (would be configured in a real app)
  static const String _remoteContentUrl = 'https://example.com/api/education-content';
  
  // Cache expiration time (24 hours)
  static const Duration _cacheExpiration = Duration(hours: 24);
  
  // Singleton pattern
  static final EducationContentRepository _instance = EducationContentRepository._internal();
  
  factory EducationContentRepository() {
    return _instance;
  }
  
  EducationContentRepository._internal();
  
  /// Fetch content from the remote server
  Future<List<EducationalContent>> fetchRemoteContent() async {
    try {
      final response = await http.get(Uri.parse(_remoteContentUrl));
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;
        final content = jsonData
            .map((item) => EducationalContent.fromJson(item as Map<String, dynamic>))
            .toList();
        
        // Save to cache
        await saveContentToCache(content);
        
        return content;
      } else {
        throw Exception('Failed to load content: ${response.statusCode}');
      }
    } catch (e) {
      // If network request fails, try loading from cache
      final cachedContent = await loadContentFromCache();
      if (cachedContent != null && cachedContent.isNotEmpty) {
        return cachedContent;
      }
      // If cache fails too, throw the original exception
      rethrow;
    }
  }
  
  /// Load content from local cache
  Future<List<EducationalContent>?> loadContentFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if cache exists and is not expired
      final timestamp = prefs.getInt(_contentCacheTimestampKey);
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        
        if (now.difference(cacheTime) < _cacheExpiration) {
          // Cache is still valid
          final cachedData = prefs.getString(_contentCacheKey);
          if (cachedData != null) {
            final jsonData = jsonDecode(cachedData) as List;
            return jsonData
                .map((item) => EducationalContent.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error loading cache: $e');
      return null;
    }
  }
  
  /// Save content to local cache
  Future<void> saveContentToCache(List<EducationalContent> content) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = content.map((c) => c.toJson()).toList();
      
      await prefs.setString(_contentCacheKey, jsonEncode(jsonData));
      await prefs.setInt(_contentCacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }
  
  /// Get list of saved content IDs
  Future<Set<String>> getSavedContentIds() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList(_savedContentKey) ?? [];
    return savedIds.toSet();
  }
  
  /// Save or remove a content ID from saved list
  Future<void> toggleSavedContent(String contentId, bool isSaved) async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = Set<String>.from(prefs.getStringList(_savedContentKey) ?? []);
    
    if (isSaved) {
      savedIds.add(contentId);
    } else {
      savedIds.remove(contentId);
    }
    
    await prefs.setStringList(_savedContentKey, savedIds.toList());
  }
  
  /// Get list of read content IDs
  Future<Set<String>> getReadContentIds() async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList(_readContentKey) ?? [];
    return readIds.toSet();
  }
  
  /// Mark a content as read
  Future<void> markContentAsRead(String contentId) async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = Set<String>.from(prefs.getStringList(_readContentKey) ?? []);
    
    if (!readIds.contains(contentId)) {
      readIds.add(contentId);
      await prefs.setStringList(_readContentKey, readIds.toList());
    }
  }
  
  /// Clear all cached content
  Future<void> clearContentCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_contentCacheKey);
    await prefs.remove(_contentCacheTimestampKey);
  }
  
  /// Get cache age in hours
  Future<double?> getCacheAge() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_contentCacheTimestampKey);
    
    if (timestamp != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(cacheTime);
      return difference.inMinutes / 60.0; // Convert to hours
    }
    
    return null;
  }
  
  /// Get saved content IDs synchronously (for internal use)
  Set<String> getSavedContentIdsSync() {
    // In a real implementation, you might want to maintain a memory cache
    // This is a simplified version that returns an empty set
    // In practice, you'd sync this with the SharedPreferences periodically
    return {};
  }
  
  /// Get read content IDs synchronously (for internal use)
  Set<String> getReadContentIdsSync() {
    // In a real implementation, you might want to maintain a memory cache
    // This is a simplified version that returns an empty set
    // In practice, you'd sync this with the SharedPreferences periodically
    return {};
  }
}