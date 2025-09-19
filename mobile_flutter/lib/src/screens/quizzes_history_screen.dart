import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../clinical_quizzes/repositories/quiz_repository.dart';
import '../clinical_quizzes/repositories/mock_quiz_repository.dart';
import '../clinical_quizzes/screens/quiz_history_screen.dart';

class QuizzesHistoryScreen extends StatelessWidget {
  const QuizzesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Create provider for repository
    return Provider<QuizRepository>(
      // Use MockQuizRepository for now, can be replaced with a real implementation later
      create: (_) => MockQuizRepository(),
      // We'll use a dispose pattern to clean up resources
      dispose: (_, repo) => (repo as MockQuizRepository).dispose(),
      child: const QuizHistoryScreen(),
    );
  }
}
