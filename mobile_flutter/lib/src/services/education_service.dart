import '../models/educational_content.dart';
import '../models/education_category.dart';
import '../models/user_risk_profile.dart';
import '../models/risk_level.dart';
import '../repositories/education_content_repository.dart';

/// Service responsible for managing educational content and personalization
class EducationService {
  // In-memory cache of content
  List<EducationalContent>? _contentCache;
  
  // Repository for content storage and retrieval
  final EducationContentRepository _repository = EducationContentRepository();
  
  // Singleton pattern
  static final EducationService _instance = EducationService._internal();
  
  factory EducationService() {
    return _instance;
  }
  
  EducationService._internal();
  
  /// Get personalized content filtered by user's risk profile
  Future<List<EducationalContent>> getPersonalizedContent(UserRiskProfile userProfile) async {
    // Get all content
    final allContent = await getAllContent();
    
    // Filter and prioritize content based on user's risk profile
    return _filterAndPrioritizeContent(allContent, userProfile);
  }
  
  /// Filter and prioritize content based on user risk profile
  List<EducationalContent> _filterAndPrioritizeContent(
    List<EducationalContent> allContent,
    UserRiskProfile userProfile
  ) {
    // Step 1: Separate content by relevance
    final highPriorityContent = <EducationalContent>[];
    final mediumPriorityContent = <EducationalContent>[];
    final lowPriorityContent = <EducationalContent>[];
    final generalContent = <EducationalContent>[];
    
    // Step 2: Get saved content IDs to mark content as saved
    final savedContentIds = _repository.getSavedContentIdsSync();
    final readContentIds = _repository.getReadContentIdsSync();
    
    for (final content in allContent) {
      // Mark as saved or read if needed
      content.isSaved = savedContentIds.contains(content.contentId);
      content.isRead = readContentIds.contains(content.contentId);
      
      // Check if this is general content that applies to all
      if (content.targetRiskFactor == 'all') {
        generalContent.add(content);
        continue;
      }
      
      // Get the user's risk level for this factor
      final userRiskLevel = userProfile.getRiskLevelFor(content.targetRiskFactor);
      
      // Check if the content is applicable for the user's risk level
      final isApplicable = content.targetRiskLevels.contains(userRiskLevel);
      
      if (isApplicable) {
        // High priority: Content targeting high or very high risk factors
        if (userRiskLevel == RiskLevel.high || userRiskLevel == RiskLevel.veryHigh) {
          highPriorityContent.add(content);
        }
        // Medium priority: Content targeting moderate risk factors
        else if (userRiskLevel == RiskLevel.moderate) {
          mediumPriorityContent.add(content);
        }
        // Low priority: Content targeting normal risk factors
        else {
          lowPriorityContent.add(content);
        }
      }
    }
    
    // Step 3: Sort each category by priority
    highPriorityContent.sort((a, b) => b.priority.compareTo(a.priority));
    mediumPriorityContent.sort((a, b) => b.priority.compareTo(a.priority));
    lowPriorityContent.sort((a, b) => b.priority.compareTo(a.priority));
    generalContent.sort((a, b) => b.priority.compareTo(a.priority));
    
    // Step 4: Combine all content with high priority first
    final result = [
      ...highPriorityContent,
      ...mediumPriorityContent,
      ...generalContent.where((c) => !c.isRead), // Show unread general content
      ...lowPriorityContent,
      ...generalContent.where((c) => c.isRead), // Show read general content last
    ];
    
    return result;
  }
  
  /// Get content filtered by category
  Future<List<EducationalContent>> getContentByCategory(
    UserRiskProfile userProfile,
    String categoryId
  ) async {
    // Get personalized content
    final personalizedContent = await getPersonalizedContent(userProfile);
    
    // Filter by category
    return personalizedContent.where((content) => content.category.id == categoryId).toList();
  }
  
  /// Get all educational content (from cache or remote)
  Future<List<EducationalContent>> getAllContent() async {
    // Return cached content if available
    if (_contentCache != null) {
      return _contentCache!;
    }
    
    try {
      // Try to load from local cache first
      final cachedContent = await _repository.loadContentFromCache();
      if (cachedContent != null) {
        _contentCache = cachedContent;
        return cachedContent;
      }
      
      // Fetch from remote if cache not available
      final content = await _repository.fetchRemoteContent();
      _contentCache = content;
      return content;
    } catch (e) {
      // In case of error, return sample data
      final sampleContent = _getSampleContent();
      _contentCache = sampleContent;
      return sampleContent;
    }
  }
  
  /// Save content to user's favorites/bookmarks
  Future<void> saveContent(String contentId, bool isSaved) async {
    await _repository.toggleSavedContent(contentId, isSaved);
    
    // Update cache if available
    if (_contentCache != null) {
      final index = _contentCache!.indexWhere((c) => c.contentId == contentId);
      if (index != -1) {
        _contentCache![index] = _contentCache![index].copyWith(isSaved: isSaved);
      }
    }
  }
  
  /// Mark content as read
  Future<void> markAsRead(String contentId) async {
    await _repository.markContentAsRead(contentId);
    
    // Update cache if available
    if (_contentCache != null) {
      final index = _contentCache!.indexWhere((c) => c.contentId == contentId);
      if (index != -1) {
        _contentCache![index] = _contentCache![index].copyWith(isRead: true);
      }
    }
  }
  
  /// Get all saved/bookmarked content
  Future<List<EducationalContent>> getSavedContent() async {
    final allContent = await getAllContent();
    final savedContentIds = await _repository.getSavedContentIds();
    
    return allContent.where((content) => 
      savedContentIds.contains(content.contentId)).toList();
  }
  
  /// Force refresh content from remote
  Future<List<EducationalContent>> refreshContent() async {
    // Clear cache
    _contentCache = null;
    await _repository.clearContentCache();
    
    try {
      // Fetch fresh content
      final content = await _repository.fetchRemoteContent();
      _contentCache = content;
      return content;
    } catch (e) {
      // If refresh fails, return sample content
      final sampleContent = _getSampleContent();
      _contentCache = sampleContent;
      return sampleContent;
    }
  }
  
  /// Get cache age in hours
  Future<double?> getCacheAge() {
    return _repository.getCacheAge();
  }
  
  /// Generate sample content for testing/development
  List<EducationalContent> _getSampleContent() {
    final now = DateTime.now();
    
    return [
      // BMI-related content
      EducationalContent(
        contentId: 'ex_adv_1',
        title: 'Start with a Daily Brisk Walk',
        body: 'Aim for at least 30 minutes of moderate-intensity exercise, like brisk walking, most days of the week. This can help burn calories and improve heart health.',
        category: EducationCategory.physicalActivity,
        targetRiskFactor: 'bmi',
        targetRiskLevels: [RiskLevel.high, RiskLevel.veryHigh],
        priority: 10,
        lastUpdated: now,
        actionableSteps: [
          'Walk for 15 minutes on your lunch break.',
          'Take the stairs instead of the elevator.',
          'Set a reminder to get up and move every hour.',
        ],
      ),
      EducationalContent(
        contentId: 'diet_adv_1',
        title: 'Focus on Whole Foods',
        body: 'Reduce processed foods high in sugar and unhealthy fats. Increase your intake of fruits, vegetables, and whole grains to feel fuller longer and manage your weight.',
        category: EducationCategory.dietNutrition,
        targetRiskFactor: 'bmi',
        targetRiskLevels: [RiskLevel.high, RiskLevel.veryHigh],
        priority: 9,
        lastUpdated: now,
        actionableSteps: [
          'Add one extra serving of vegetables to your dinner.',
          'Swap white bread for whole-grain.',
          'Drink a glass of water before each meal.',
        ],
      ),
      
      // Cholesterol-related content
      EducationalContent(
        contentId: 'diet_adv_ldl',
        title: 'Choose Heart-Healthy Fats',
        body: 'Not all fats are created equal. Replace saturated and trans fats with healthier monounsaturated and polyunsaturated fats to help manage cholesterol levels.',
        category: EducationCategory.dietNutrition,
        targetRiskFactor: 'ldl_cholesterol',
        targetRiskLevels: [RiskLevel.high, RiskLevel.veryHigh],
        priority: 10,
        lastUpdated: now,
        references: [
          'https://www.heart.org/en/health-topics/cholesterol/prevention-and-treatment-of-high-cholesterol-hyperlipidemia',
        ],
        actionableSteps: [
          'Use olive oil instead of butter when cooking.',
          'Eat fatty fish like salmon twice a week.',
          'Choose nuts and seeds for snacks instead of processed foods.',
        ],
      ),
      
      // Blood pressure content
      EducationalContent(
        contentId: 'stress_adv_1',
        title: 'Mindfulness for Blood Pressure Management',
        body: 'Regular meditation and mindfulness practices can help reduce stress hormones that raise blood pressure. Even a few minutes a day can make a difference.',
        category: EducationCategory.stressManagement,
        targetRiskFactor: 'blood_pressure',
        targetRiskLevels: [RiskLevel.moderate, RiskLevel.high, RiskLevel.veryHigh],
        priority: 8,
        lastUpdated: now,
        actionableSteps: [
          'Try a 5-minute guided meditation before bedtime.',
          'Practice deep breathing for 2 minutes when feeling stressed.',
          'Use a mindfulness app to build a daily practice.',
        ],
      ),
      
      // Smoking content
      EducationalContent(
        contentId: 'smoking_adv_1',
        title: 'First Steps to Quitting',
        body: 'Quitting smoking is one of the most important things you can do for your health. It lowers your risk for heart disease, stroke, and many cancers.',
        category: EducationCategory.smokingCessation,
        targetRiskFactor: 'smoking',
        targetRiskLevels: [RiskLevel.moderate, RiskLevel.high, RiskLevel.veryHigh],
        priority: 10,
        lastUpdated: now,
        references: [
          'https://www.cdc.gov/tobacco/quit_smoking/how_to_quit/index.htm',
        ],
        actionableSteps: [
          'Set a quit date within the next two weeks.',
          'Tell friends and family about your plan to quit for support.',
          'Remove all tobacco products from your home and car.',
          'Talk to your doctor about medication or nicotine replacement therapy.',
        ],
      ),
      
      // General wellness content
      EducationalContent(
        contentId: 'gen_adv_1',
        title: 'The Power of Quality Sleep',
        body: 'Getting 7-9 hours of quality sleep each night helps regulate hormones, reduce stress, and improve overall health outcomes.',
        category: EducationCategory.generalWellness,
        targetRiskFactor: 'all',
        targetRiskLevels: [RiskLevel.normal, RiskLevel.moderate, RiskLevel.high, RiskLevel.veryHigh],
        priority: 7,
        lastUpdated: now,
        actionableSteps: [
          'Create a consistent sleep schedule, even on weekends.',
          'Make your bedroom cool, dark, and quiet.',
          'Avoid screens one hour before bedtime.',
        ],
      ),
    ];
  }
}