import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';

/// Repository for managing questionnaires - fetching, storing, and retrieving them
class QuestionnaireRepository {
  // Keys for shared preferences
  static const String _questionnairesKey = 'questionnaires';
  static const String _questionnairesTimestampKey = 'questionnaires_timestamp';
  static const String _questionnaireCachePrefix = 'questionnaire_';
  static const String _sessionCachePrefix = 'questionnaire_session_';
  static const String _responseHistoryKey = 'questionnaire_responses';
  
  // Endpoint for fetching questionnaire definitions
  // In a real app, this would be a configuration value
  final String _remoteEndpoint;
  
  // Cache duration
  static const Duration _cacheDuration = Duration(days: 1);
  
  // UUIDs for generating unique IDs
  final _uuid = const Uuid();
  
  /// Constructor for the QuestionnaireRepository
  QuestionnaireRepository({
    String? remoteEndpoint,
  }) : _remoteEndpoint = remoteEndpoint ?? 'https://example.com/api/questionnaires';
  
  /// Fetch all available questionnaire metadata from the server or cache
  Future<List<Map<String, dynamic>>> fetchQuestionnairesMetadata() async {
    try {
      // Try to use cache first
      final cachedData = await _getCachedQuestionnairesMetadata();
      if (cachedData != null) {
        return cachedData;
      }
      
      // If cache is not available or expired, fetch from the server
      final response = await http.get(Uri.parse('$_remoteEndpoint/list'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> metadata = 
            data.map((item) => Map<String, dynamic>.from(item)).toList();
        
        // Cache the result
        await _cacheQuestionnairesMetadata(metadata);
        
        return metadata;
      } else {
        throw Exception('Failed to load questionnaires: ${response.statusCode}');
      }
    } catch (e) {
      // If there's an error, try to return cached data anyway
      final cachedData = await _getCachedQuestionnairesMetadata();
      if (cachedData != null) {
        return cachedData;
      }
      
      // If no cache available, rethrow the error
      rethrow;
    }
  }
  
  /// Fetch a specific questionnaire from the server or cache
  Future<Questionnaire> fetchQuestionnaire(String questionnaireId) async {
    try {
      // Try to use cache first
      final cachedQuestionnaire = await _getCachedQuestionnaire(questionnaireId);
      if (cachedQuestionnaire != null) {
        return cachedQuestionnaire;
      }
      
      // If cache is not available, fetch from the server
      final response = await http.get(Uri.parse('$_remoteEndpoint/$questionnaireId'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final questionnaire = Questionnaire.fromJson(data);
        
        // Cache the result
        await _cacheQuestionnaire(questionnaire);
        
        return questionnaire;
      } else {
        throw Exception('Failed to load questionnaire: ${response.statusCode}');
      }
    } catch (e) {
      // If there's an error, try to return cached data anyway
      final cachedQuestionnaire = await _getCachedQuestionnaire(questionnaireId);
      if (cachedQuestionnaire != null) {
        return cachedQuestionnaire;
      }
      
      // If no cache available, rethrow the error
      rethrow;
    }
  }
  
  /// Get cached questionnaires metadata
  Future<List<Map<String, dynamic>>?> _getCachedQuestionnairesMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if the cache exists and is not expired
    final timestamp = prefs.getInt(_questionnairesTimestampKey);
    if (timestamp != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) < _cacheDuration) {
        final cachedData = prefs.getString(_questionnairesKey);
        if (cachedData != null) {
          final List<dynamic> data = json.decode(cachedData);
          return data.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      }
    }
    
    return null;
  }
  
  /// Cache questionnaires metadata
  Future<void> _cacheQuestionnairesMetadata(List<Map<String, dynamic>> metadata) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_questionnairesKey, json.encode(metadata));
    await prefs.setInt(_questionnairesTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }
  
  /// Get a cached questionnaire
  Future<Questionnaire?> _getCachedQuestionnaire(String questionnaireId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_questionnaireCachePrefix$questionnaireId';
    
    final cachedData = prefs.getString(key);
    if (cachedData != null) {
      return Questionnaire.fromJson(json.decode(cachedData));
    }
    
    return null;
  }
  
  /// Cache a questionnaire
  Future<void> _cacheQuestionnaire(Questionnaire questionnaire) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_questionnaireCachePrefix${questionnaire.questionnaireId}';
    await prefs.setString(key, json.encode(questionnaire.toJson()));
  }
  
  /// Save an in-progress questionnaire session
  Future<void> saveSession(QuestionnaireSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_sessionCachePrefix${session.questionnaire.questionnaireId}';
    await prefs.setString(key, json.encode(session.toJson()));
  }
  
  /// Get an in-progress questionnaire session
  Future<QuestionnaireSession?> getSession(String questionnaireId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_sessionCachePrefix$questionnaireId';
    
    final cachedData = prefs.getString(key);
    if (cachedData != null) {
      final sessionData = json.decode(cachedData);
      final questionnaire = await fetchQuestionnaire(questionnaireId);
      return QuestionnaireSession.fromJson(sessionData, questionnaire);
    }
    
    return null;
  }
  
  /// Clear an in-progress questionnaire session
  Future<void> clearSession(String questionnaireId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_sessionCachePrefix$questionnaireId';
    await prefs.remove(key);
  }
  
  /// Save a completed questionnaire response
  Future<void> saveResponse(QuestionnaireResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing responses
    final responsesList = await getResponseHistory();
    
    // Add the new response
    responsesList.add(response);
    
    // Save the updated list
    await prefs.setString(_responseHistoryKey, 
      json.encode(responsesList.map((r) => r.toJson()).toList()));
  }
  
  /// Get all completed questionnaire responses
  Future<List<QuestionnaireResponse>> getResponseHistory() async {
    final prefs = await SharedPreferences.getInstance();
    
    final historyData = prefs.getString(_responseHistoryKey);
    if (historyData != null) {
      final List<dynamic> responses = json.decode(historyData);
      return responses.map((r) => QuestionnaireResponse.fromJson(r)).toList();
    }
    
    return [];
  }
  
  /// Get responses for a specific questionnaire
  Future<List<QuestionnaireResponse>> getResponsesForQuestionnaire(
    String questionnaireId
  ) async {
    final responses = await getResponseHistory();
    return responses.where((r) => r.questionnaireId == questionnaireId).toList();
  }
  
  /// Get the most recent response for a questionnaire
  Future<QuestionnaireResponse?> getMostRecentResponse(
    String questionnaireId
  ) async {
    final responses = await getResponsesForQuestionnaire(questionnaireId);
    
    if (responses.isNotEmpty) {
      // Sort by date completed in descending order
      responses.sort((a, b) => b.dateCompleted.compareTo(a.dateCompleted));
      return responses.first;
    }
    
    return null;
  }
  
  /// Generate a unique response ID
  String generateResponseId() {
    return _uuid.v4();
  }
  
  /// Clear the questionnaire cache
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    
    for (final key in allKeys) {
      if (key.startsWith(_questionnaireCachePrefix) || 
          key == _questionnairesKey ||
          key == _questionnairesTimestampKey) {
        await prefs.remove(key);
      }
    }
  }
  
  /// Force refresh questionnaires from the server
  Future<List<Map<String, dynamic>>> refreshQuestionnaires() async {
    await clearCache();
    return fetchQuestionnairesMetadata();
  }
}