import 'package:flutter/material.dart';
import '../models/education_category.dart';
import '../models/educational_content.dart';
import '../models/user_risk_profile.dart';
import '../models/risk_level.dart';
import '../services/education_service.dart';
import '../widgets/education_content_card.dart';
import 'education_detail_screen.dart';

class EducationDashboardScreen extends StatefulWidget {
  final UserRiskProfile? userRiskProfile;
  
  const EducationDashboardScreen({
    Key? key,
    this.userRiskProfile,
  }) : super(key: key);

  @override
  _EducationDashboardScreenState createState() => _EducationDashboardScreenState();
}

class _EducationDashboardScreenState extends State<EducationDashboardScreen>
    with SingleTickerProviderStateMixin {
  final EducationService _educationService = EducationService();
  late TabController _tabController;
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  
  // Content by category
  final Map<String, List<EducationalContent>> _contentByCategory = {};
  List<EducationalContent> _savedContent = [];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize tab controller with number of categories + Saved tab
    _tabController = TabController(
      length: EducationCategory.values.length + 1, 
      vsync: this,
    );
    
    // Load content
    _loadContent();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });
    
    try {
      // Get user profile or create a dummy one if not available
      final userProfile = widget.userRiskProfile ?? _createDummyUserProfile();
      
      // Get all personalized content
      final allContent = await _educationService.getPersonalizedContent(userProfile);
      
      // Get saved content
      final saved = await _educationService.getSavedContent();
      
      // Organize content by category
      final contentMap = <String, List<EducationalContent>>{};
      
      for (final category in EducationCategory.values) {
        contentMap[category.id] = allContent
            .where((content) => content.category == category)
            .toList();
      }
      
      if (mounted) {
        setState(() {
          _contentByCategory.clear();
          _contentByCategory.addAll(contentMap);
          _savedContent = saved;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = 'Failed to load educational content: ${e.toString()}';
        });
      }
    }
  }
  
  // Create a dummy user profile for testing/development
  UserRiskProfile _createDummyUserProfile() {
    return UserRiskProfile(
      userId: 'test_user',
      overallRiskLevel: RiskLevel.moderate,
      specificRiskFactors: {
        'bmi': RiskLevel.high,
        'ldl_cholesterol': RiskLevel.moderate,
        'blood_pressure': RiskLevel.normal,
        'blood_sugar': RiskLevel.normal,
        'smoking': RiskLevel.normal,
      },
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/quiz-history'),
        icon: const Icon(Icons.history),
        label: const Text('Quiz History'),
        tooltip: 'View your quiz history',
      ),
      appBar: AppBar(
        title: const Text('Health Education'),
        actions: [
          // Quiz button
          IconButton(
            icon: const Icon(Icons.quiz),
            onPressed: () => Navigator.pushNamed(context, '/quizzes'),
            tooltip: 'Clinical Knowledge Quizzes',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContent,
            tooltip: 'Refresh content',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            // Category tabs
            ...EducationCategory.values.map((category) => Tab(
              text: category.name,
              icon: Icon(_getCategoryIcon(category)),
            )),
            // Saved tab
            const Tab(
              text: 'Saved',
              icon: Icon(Icons.bookmark),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isError
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Category content views
                    ...EducationCategory.values.map((category) => 
                      _buildCategoryContentList(category)),
                    // Saved content view
                    _buildSavedContentList(),
                  ],
                ),
    );
  }
  
  Widget _buildCategoryContentList(EducationCategory category) {
    final categoryContent = _contentByCategory[category.id] ?? [];
    
    if (categoryContent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${category.name} advice available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back later for updates',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadContent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: categoryContent.length,
        itemBuilder: (context, index) {
          final content = categoryContent[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: EducationContentCard(
              content: content,
              onTap: () => _navigateToDetail(content),
              onSaveTap: () => _toggleSaveContent(content),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSavedContentList() {
    if (_savedContent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No saved content yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the bookmark icon to save advice for later',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _savedContent.length,
      itemBuilder: (context, index) {
        final content = _savedContent[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: EducationContentCard(
            content: content,
            onTap: () => _navigateToDetail(content),
            onSaveTap: () => _toggleSaveContent(content),
          ),
        );
      },
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48.0,
            ),
            const SizedBox(height: 16.0),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton.icon(
              onPressed: _loadContent,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToDetail(EducationalContent content) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EducationDetailScreen(content: content),
      ),
    );
    
    // Refresh content after returning from detail screen
    if (result == true) {
      _loadContent();
    } else {
      // Just refresh saved status
      _updateContentStatus(content.contentId);
    }
  }
  
  void _toggleSaveContent(EducationalContent content) async {
    final newSavedState = !content.isSaved;
    await _educationService.saveContent(content.contentId, newSavedState);
    
    _updateContentStatus(content.contentId);
    
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newSavedState 
            ? 'Saved to your favorites' 
            : 'Removed from favorites'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  // Update the status of a content item in all lists
  void _updateContentStatus(String contentId) {
    setState(() {
      // Update in category lists
      for (final category in _contentByCategory.keys) {
        final index = _contentByCategory[category]!.indexWhere(
          (c) => c.contentId == contentId
        );
        
        if (index != -1) {
          final updatedContent = _contentByCategory[category]![index];
          _contentByCategory[category]![index] = updatedContent;
        }
      }
      
      // Update saved content list
      _loadContent();
    });
  }
  
  // Helper method to get icon for a category
  IconData _getCategoryIcon(EducationCategory category) {
    switch (category) {
      case EducationCategory.dietNutrition:
        return Icons.restaurant;
      case EducationCategory.physicalActivity:
        return Icons.fitness_center;
      case EducationCategory.stressManagement:
        return Icons.spa;
      case EducationCategory.smokingCessation:
        return Icons.smoke_free;
      case EducationCategory.generalWellness:
        return Icons.favorite;
    }
  }
}