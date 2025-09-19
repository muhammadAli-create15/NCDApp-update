import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../clinical_quizzes/models/models.dart';
import '../clinical_quizzes/repositories/quiz_repository.dart';
import '../clinical_quizzes/repositories/mock_quiz_repository.dart';
import '../clinical_quizzes/widgets/widgets.dart';
import '../clinical_quizzes/screens/quiz_library_screen.dart';

class QuizzesScreen extends StatelessWidget {
  const QuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Provider to make the repository available throughout the quiz feature
    return Provider<QuizRepository>(
      // Use MockQuizRepository for now, can be replaced with a real implementation later
      create: (_) => MockQuizRepository(),
      // We'll use a dispose pattern to clean up resources
      dispose: (_, repo) => (repo as MockQuizRepository).dispose(),
      child: const QuizLibraryScreen(),
    );
  }
}

