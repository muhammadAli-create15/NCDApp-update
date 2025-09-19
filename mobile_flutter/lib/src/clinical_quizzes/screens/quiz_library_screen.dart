import 'package:flutter/material.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';
import '../widgets/widgets.dart';
import 'quiz_detail_screen.dart';

/// Screen that displays the library of available quizzes
class QuizLibraryScreen extends StatefulWidget {
  const QuizLibraryScreen({Key? key}) : super(key: key);

  @override
  State<QuizLibraryScreen> createState() => _QuizLibraryScreenState();
}

class _QuizLibraryScreenState extends State<QuizLibraryScreen> {
  final QuizRepository _repository = MockQuizRepository();
  List<Quiz> _quizzes = [];
  Map<String, QuizAttempt> _bestAttempts = {};
  bool _isLoading = true;
  QuizCategory? _selectedCategory;
  QuizDifficulty? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();

    // Listen for changes in quiz data
    _repository.onQuizDataChanged.listen((_) {
      _loadQuizzes();
    });
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch all available quizzes
      final quizzes = await _repository.getAvailableQuizzes();
      
      // Get the current user's ID (simulated here)
      const userId = 'user123';
      
      // Fetch all attempts for this user
      final attempts = await _repository.getUserAttempts(userId);
      
      // Group attempts by quiz and find the best score for each
      final bestAttemptsMap = <String, QuizAttempt>{};
      
      for (final attempt in attempts) {
        if (!bestAttemptsMap.containsKey(attempt.quizId) || 
            attempt.score > bestAttemptsMap[attempt.quizId]!.score) {
          bestAttemptsMap[attempt.quizId] = attempt;
        }
      }

      setState(() {
        _quizzes = quizzes;
        _bestAttempts = bestAttemptsMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load quizzes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Knowledge Quizzes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/quiz-history'),
            tooltip: 'View quiz history',
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncWithRemote,
            tooltip: 'Sync with server',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadQuizzes,
              child: Column(
                children: [
                  _buildFilters(),
                  Expanded(child: _buildQuizList()),
                ],
              ),
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCategoryDropdown(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDifficultyDropdown(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<QuizCategory?>(
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      value: _selectedCategory,
      items: [
        const DropdownMenuItem<QuizCategory?>(
          value: null,
          child: Text('All Categories'),
        ),
        ...QuizCategory.values.map(
          (category) => DropdownMenuItem<QuizCategory>(
            value: category,
            child: Text(category.displayName),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
    );
  }

  Widget _buildDifficultyDropdown() {
    return DropdownButtonFormField<QuizDifficulty?>(
      decoration: const InputDecoration(
        labelText: 'Difficulty',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      value: _selectedDifficulty,
      items: [
        const DropdownMenuItem<QuizDifficulty?>(
          value: null,
          child: Text('All Levels'),
        ),
        ...QuizDifficulty.values.map(
          (difficulty) => DropdownMenuItem<QuizDifficulty>(
            value: difficulty,
            child: Text(difficulty.displayName),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedDifficulty = value;
        });
      },
    );
  }

  Widget _buildQuizList() {
    final filteredQuizzes = _filterQuizzes();
    
    if (filteredQuizzes.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredQuizzes.length,
      itemBuilder: (context, index) {
        final quiz = filteredQuizzes[index];
        final bestAttempt = _bestAttempts[quiz.quizId];
        
        return QuizCard(
          quiz: quiz,
          bestScore: bestAttempt?.score,
          isPassed: bestAttempt?.passed ?? false,
          onTap: () => _navigateToQuizDetail(quiz),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    if (_quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.quiz,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No quizzes available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Check back later for new quizzes'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _syncWithRemote,
              icon: const Icon(Icons.sync),
              label: const Text('Sync Now'),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.filter_list,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No matching quizzes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Try changing your filter settings'),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }
  }

  List<Quiz> _filterQuizzes() {
    return _quizzes.where((quiz) {
      // Apply category filter
      if (_selectedCategory != null && quiz.category != _selectedCategory) {
        return false;
      }
      
      // Apply difficulty filter
      if (_selectedDifficulty != null && quiz.difficulty != _selectedDifficulty) {
        return false;
      }
      
      return true;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedDifficulty = null;
    });
  }

  Future<void> _syncWithRemote() async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Syncing with server...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      await _repository.syncWithRemote();
      final hasUpdates = await _repository.checkForUpdates();
      
      if (hasUpdates) {
        await _loadQuizzes();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('New quiz content available!'),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('You have the latest quiz content'),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to sync: $e');
    }
  }

  void _navigateToQuizDetail(Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizDetailScreen(quiz: quiz),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}