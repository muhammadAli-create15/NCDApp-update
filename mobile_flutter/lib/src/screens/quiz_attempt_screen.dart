import 'package:flutter/material.dart';
import '../clinical_quizzes/models/models.dart';
import '../clinical_quizzes/screens/quiz_session_screen.dart';
import '../clinical_quizzes/repositories/quiz_repository.dart';
import 'package:provider/provider.dart';

class QuizAttemptScreen extends StatelessWidget {
  const QuizAttemptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Extract quiz ID from route arguments
    final args = ModalRoute.of(context)!.settings.arguments;
    
    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('No quiz selected')),
      );
    }
    
    // Check if args is a string (quiz ID) or a Quiz object
    String quizId;
    if (args is String) {
      quizId = args;
    } else if (args is Map<String, dynamic> && args.containsKey('quizId')) {
      quizId = args['quizId'];
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('Invalid quiz data')),
      );
    }
    
    // Get the repository from the provider
    final repository = Provider.of<QuizRepository>(context, listen: false);
    
    // First load the quiz and create an attempt
    return FutureBuilder<Quiz>(
      future: repository.getQuizById(quizId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading Quiz')),
            body: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Error loading quiz: ${snapshot.error}')),
          );
        } else if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Quiz Not Found')),
            body: const Center(child: Text('Quiz not found')),
          );
        }
        
        // We have the quiz data, now create an attempt
        final quiz = snapshot.data!;
        
        // Use another FutureBuilder to create the quiz attempt
        return FutureBuilder<QuizAttempt>(
          future: repository.startQuizAttempt('user123', quizId),  // 'user123' is a placeholder user ID
          builder: (context, attemptSnapshot) {
            if (attemptSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                appBar: AppBar(title: Text('Starting ${quiz.title}')),
                body: const Center(child: CircularProgressIndicator()),
              );
            } else if (attemptSnapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: Center(child: Text('Error starting quiz attempt: ${attemptSnapshot.error}')),
              );
            } else if (!attemptSnapshot.hasData) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Failed to create quiz attempt')),
              );
            }
            
            // We have both the quiz and the attempt, show the quiz session screen
            return QuizSessionScreen(
              quiz: quiz,
              attemptId: attemptSnapshot.data!.attemptId,
            );
          },
        );
      },
    );
  }
}


