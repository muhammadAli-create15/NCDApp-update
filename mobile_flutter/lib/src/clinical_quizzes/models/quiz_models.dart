import 'package:uuid/uuid.dart';
import '../models/quiz_models.dart';

/// Enum for quiz categories
enum QuizCategory {
  diabetes,
  hypertension,
  cardiovascular,
  respiratory,
  general
}

/// Enum for quiz difficulty levels
enum QuizDifficulty {
  beginner,
  intermediate,
  advanced
}

/// Enum for question types
enum QuestionType {
  multipleChoice,
  multiSelect,
  trueFalse
}

/// Represents a quiz option
class Option {
  final String id;
  final String text;
  final bool isCorrect;
  
  const Option({
    required this.id,
    required this.text,
    required this.isCorrect,
  });
}

/// Represents a quiz question
class Question {
  final String id;
  final String text;
  final QuestionType type;
  final List<Option> options;
  final String explanation;
  
  const Question({
    required this.id,
    required this.text,
    required this.type,
    required this.options,
    required this.explanation,
  });
  
  /// Checks if the provided answers are correct
  bool areAnswersCorrect(List<String> answers) {
    if (type == QuestionType.multipleChoice || type == QuestionType.trueFalse) {
      // For single-select questions
      if (answers.length != 1) return false;
      return options.any((o) => o.id == answers.first && o.isCorrect);
    } else {
      // For multi-select questions
      final correctOptionIds = options.where((o) => o.isCorrect).map((o) => o.id).toSet();
      final userAnswersSet = answers.toSet();
      return correctOptionIds.length == userAnswersSet.length && 
             correctOptionIds.containsAll(userAnswersSet);
    }
  }
}

/// Represents a quiz
class Quiz {
  final String id;
  final String title;
  final String description;
  final QuizCategory category;
  final QuizDifficulty difficulty;
  final int timeLimit; // in minutes
  final List<Question> questions;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.timeLimit,
    required this.questions,
    required this.createdAt,
    required this.updatedAt,
  });
  
  /// Returns the number of questions in the quiz
  int get questionCount => questions.length;
  
  /// Determines if the quiz is passed based on correct answers
  bool isPassed(double correctAnswers) {
    // Default pass is 70% correct
    return (correctAnswers / questionCount) * 100 >= 70;
  }
}

/// Represents a quiz attempt
class QuizAttempt {
  final String id;
  final String quizId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final double score;
  final Map<String, List<String>> answers;
  final bool completed;
  
  const QuizAttempt({
    required this.id,
    required this.quizId,
    this.userId = '',
    required this.startTime,
    this.endTime,
    required this.score,
    required this.answers,
    required this.completed,
  });
  
  /// Creates a copy of the attempt with updated fields
  QuizAttempt copyWith({
    String? id,
    String? quizId,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    double? score,
    Map<String, List<String>>? answers,
    bool? completed,
  }) {
    return QuizAttempt(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      score: score ?? this.score,
      answers: answers ?? this.answers,
      completed: completed ?? this.completed,
    );
  }
}

/// Provides mock quiz data for testing and development purposes
class MockQuizData {
  /// Returns a list of sample quizzes covering different NCD topics
  static List<Quiz> getSampleQuizzes() {
    return [
      _createDiabetesQuiz(),
      _createHypertensionQuiz(),
      _createAsthmaQuiz(),
      _createCOPDQuiz(),
      _createCardiovascularQuiz(),
    ];
  }

  /// Creates a sample diabetes quiz
  static Quiz _createDiabetesQuiz() {
    return Quiz(
      id: const Uuid().v4(),
      title: "Diabetes Management",
      description: "Test your knowledge on current diabetes management guidelines and treatment options.",
      category: QuizCategory.diabetes,
      difficulty: QuizDifficulty.intermediate,
      timeLimit: 15, // 15 minutes
      questions: [
        Question(
          id: const Uuid().v4(),
          text: "What is the recommended HbA1c target for most adults with diabetes?",
          type: QuestionType.multipleChoice,
          explanation: "Clinical guidelines recommend an HbA1c target of <7% for most adults with diabetes, though targets may be individualized based on patient factors.",
          options: [
            Option(id: "A", text: "<6.5%", isCorrect: false),
            Option(id: "B", text: "<7%", isCorrect: true),
            Option(id: "C", text: "<8%", isCorrect: false),
            Option(id: "D", text: "<9%", isCorrect: false),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "Which of the following is NOT a first-line medication for type 2 diabetes according to current guidelines?",
          type: QuestionType.multipleChoice,
          explanation: "Metformin is the first-line medication for type 2 diabetes. SGLT-2 inhibitors, GLP-1 receptor agonists, and DPP-4 inhibitors are typically second or third-line options, with insulin being used when other options fail or in specific circumstances.",
          options: [
            Option(id: "A", text: "Metformin", isCorrect: false),
            Option(id: "B", text: "SGLT-2 inhibitor", isCorrect: false),
            Option(id: "C", text: "Insulin", isCorrect: true),
            Option(id: "D", text: "GLP-1 receptor agonist", isCorrect: false),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "Which of the following is a key component of diabetes self-management education?",
          type: QuestionType.multipleChoice,
          explanation: "All options are important components of diabetes self-management education, but regular blood glucose monitoring is particularly critical as it allows patients to track their glycemic control and adjust behaviors accordingly.",
          options: [
            Option(id: "A", text: "Regular blood glucose monitoring", isCorrect: true),
            Option(id: "B", text: "Exercise planning", isCorrect: false),
            Option(id: "C", text: "Meal planning", isCorrect: false),
            Option(id: "D", text: "Foot care education", isCorrect: false),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "What is the primary mechanism of action of SGLT-2 inhibitors?",
          type: QuestionType.multipleChoice,
          explanation: "SGLT-2 inhibitors work by inhibiting sodium-glucose cotransporter-2 in the proximal renal tubules, which reduces glucose reabsorption and increases urinary glucose excretion.",
          options: [
            Option(id: "A", text: "Increase insulin secretion from pancreatic beta cells", isCorrect: false),
            Option(id: "B", text: "Decrease glucose production in the liver", isCorrect: false),
            Option(id: "C", text: "Increase glucose uptake in muscle cells", isCorrect: false),
            Option(id: "D", text: "Increase glucose excretion in urine", isCorrect: true),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "Select all complications that are associated with uncontrolled diabetes:",
          type: QuestionType.multiSelect,
          explanation: "Uncontrolled diabetes can lead to multiple complications including nephropathy (kidney disease), retinopathy (eye damage), neuropathy (nerve damage), and cardiovascular disease.",
          options: [
            Option(id: "A", text: "Diabetic nephropathy", isCorrect: true),
            Option(id: "B", text: "Diabetic retinopathy", isCorrect: true),
            Option(id: "C", text: "Peripheral neuropathy", isCorrect: true),
            Option(id: "D", text: "Hypertrichosis", isCorrect: false),
          ],
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
    );
  }

  /// Creates a sample hypertension quiz
  static Quiz _createHypertensionQuiz() {
    return Quiz(
      id: const Uuid().v4(),
      title: "Hypertension Assessment",
      description: "Review your knowledge on hypertension diagnosis and treatment protocols.",
      category: QuizCategory.hypertension,
      difficulty: QuizDifficulty.beginner,
      timeLimit: 10, // 10 minutes
      questions: [
        Question(
          id: const Uuid().v4(),
          text: "According to current guidelines, at what blood pressure threshold is hypertension diagnosed?",
          type: QuestionType.multipleChoice,
          explanation: "According to most current guidelines, hypertension is diagnosed at BP ≥130/80 mmHg, which was lowered from the previous threshold of 140/90 mmHg.",
          options: [
            Option(id: "A", text: "≥120/70 mmHg", isCorrect: false),
            Option(id: "B", text: "≥130/80 mmHg", isCorrect: true),
            Option(id: "C", text: "≥140/90 mmHg", isCorrect: false),
            Option(id: "D", text: "≥150/95 mmHg", isCorrect: false),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "Which class of antihypertensive medications is contraindicated in pregnancy?",
          type: QuestionType.multipleChoice,
          explanation: "ACE inhibitors and ARBs are contraindicated during pregnancy due to the risk of fetal renal damage and other developmental abnormalities.",
          options: [
            Option(id: "A", text: "Calcium channel blockers", isCorrect: false),
            Option(id: "B", text: "ACE inhibitors", isCorrect: true),
            Option(id: "C", text: "Beta blockers", isCorrect: false),
            Option(id: "D", text: "Thiazide diuretics", isCorrect: false),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "What is the recommended blood pressure target for patients with diabetes?",
          type: QuestionType.multipleChoice,
          explanation: "For patients with diabetes, current guidelines recommend a blood pressure target of <130/80 mmHg to reduce the risk of cardiovascular events and microvascular complications.",
          options: [
            Option(id: "A", text: "<130/80 mmHg", isCorrect: true),
            Option(id: "B", text: "<140/90 mmHg", isCorrect: false),
            Option(id: "C", text: "<150/90 mmHg", isCorrect: false),
            Option(id: "D", text: "<120/70 mmHg", isCorrect: false),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "True or False: White coat hypertension has no clinical significance and requires no follow-up.",
          type: QuestionType.trueFalse,
          explanation: "False. While white coat hypertension (elevated BP only in clinical settings) was once thought to be benign, recent evidence suggests it may be associated with increased cardiovascular risk and should be monitored.",
          options: [
            Option(id: "A", text: "True", isCorrect: false),
            Option(id: "B", text: "False", isCorrect: true),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "Which of these lifestyle modifications have been proven to reduce blood pressure? Select all that apply:",
          type: QuestionType.multiSelect,
          explanation: "The DASH diet, regular physical activity, and sodium restriction have all been proven in clinical studies to reduce blood pressure. Stress management techniques may also help.",
          options: [
            Option(id: "A", text: "DASH diet", isCorrect: true),
            Option(id: "B", text: "Regular physical activity", isCorrect: true),
            Option(id: "C", text: "Sodium restriction", isCorrect: true),
            Option(id: "D", text: "Increased caffeine intake", isCorrect: false),
          ],
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now().subtract(const Duration(days: 15)),
    );
  }

  /// Creates a sample asthma quiz
  static Quiz _createAsthmaQuiz() {
    return Quiz(
      id: const Uuid().v4(),
      title: "Asthma Management Principles",
      description: "Test your knowledge of asthma diagnosis, classification, and treatment strategies.",
      category: QuizCategory.respiratory,
      difficulty: QuizDifficulty.intermediate,
      timeLimit: 12, // 12 minutes
      questions: [
        Question(
          id: const Uuid().v4(),
          text: "Which of the following is NOT a typical symptom of asthma?",
          type: QuestionType.multipleChoice,
          explanation: "While wheezing, coughing, and shortness of breath are classic asthma symptoms, chest pain is not typically a primary symptom of asthma and may indicate other conditions.",
          options: [
            Option(id: "A", text: "Wheezing", isCorrect: false),
            Option(id: "B", text: "Coughing", isCorrect: false),
            Option(id: "C", text: "Chest pain", isCorrect: true),
            Option(id: "D", text: "Shortness of breath", isCorrect: false),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "Which medication class is considered first-line controller therapy for persistent asthma?",
          type: QuestionType.multipleChoice,
          explanation: "Inhaled corticosteroids (ICS) are the gold standard first-line controller medication for persistent asthma due to their efficacy in reducing airway inflammation.",
          options: [
            Option(id: "A", text: "Short-acting beta agonists (SABA)", isCorrect: false),
            Option(id: "B", text: "Inhaled corticosteroids (ICS)", isCorrect: true),
            Option(id: "C", text: "Leukotriene modifiers", isCorrect: false),
            Option(id: "D", text: "Long-acting beta agonists (LABA) alone", isCorrect: false),
          ],
        ),
        Question(
          id: "A3",
          text: "True or False: Spirometry can be used to confirm an asthma diagnosis.",
          type: QuestionType.trueFalse,
          explanation: "True. Spirometry showing reversible airflow obstruction (improvement in FEV1 ≥12% and ≥200 mL after bronchodilator) supports an asthma diagnosis.",
          options: [
            Option(id: "A", text: "True", isCorrect: true),
            Option(id: "B", text: "False", isCorrect: false),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "What is the primary goal of asthma management according to current guidelines?",
          type: QuestionType.multipleChoice,
          explanation: "The primary goal of asthma management is to achieve and maintain control of symptoms, which includes minimizing daytime and nighttime symptoms, maintaining normal activity levels, and preventing exacerbations.",
          options: [
            Option(id: "A", text: "Complete cure of the disease", isCorrect: false),
            Option(id: "B", text: "Symptom control and risk reduction", isCorrect: true),
            Option(id: "C", text: "Elimination of all medication use", isCorrect: false),
            Option(id: "D", text: "Preventing all exacerbations", isCorrect: false),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "Which of the following are common triggers for asthma exacerbations? Select all that apply:",
          type: QuestionType.multiSelect,
          explanation: "Respiratory infections, allergens, exercise, and cold air are all well-documented triggers for asthma symptoms and exacerbations.",
          options: [
            Option(id: "A", text: "Respiratory infections", isCorrect: true),
            Option(id: "B", text: "Allergen exposure", isCorrect: true),
            Option(id: "C", text: "Exercise", isCorrect: true),
            Option(id: "D", text: "Cold air", isCorrect: true),
          ],
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    );
  }

  /// Creates a sample COPD quiz
  static Quiz _createCOPDQuiz() {
    return Quiz(
      id: const Uuid().v4(),
      title: "COPD Assessment",
      description: "Review key concepts in COPD diagnosis, staging, and management strategies.",
      category: QuizCategory.respiratory,
      difficulty: QuizDifficulty.advanced,
      timeLimit: 15, // 15 minutes
      questions: [
        Question(
          id: const Uuid().v4(),
          text: "Which spirometry result is required for a diagnosis of COPD?",
          type: QuestionType.multipleChoice,
          explanation: "A post-bronchodilator FEV1/FVC ratio <0.7 is the spirometric criterion for COPD diagnosis according to GOLD guidelines.",
          options: [
            Option(id: "A", text: "FEV1 <80% predicted", isCorrect: false),
            Option(id: "B", text: "FEV1/FVC ratio <0.7", isCorrect: true),
            Option(id: "C", text: "FVC <80% predicted", isCorrect: false),
            Option(id: "D", text: "TLC >120% predicted", isCorrect: false),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "Which of the following is NOT a component of the ABCD assessment tool for COPD?",
          type: QuestionType.multipleChoice,
          explanation: "The ABCD assessment tool includes symptom burden, exacerbation history, and spirometric classification. Oxygen saturation is not directly part of the ABCD tool, though it's important in clinical assessment.",
          options: [
            Option(id: "A", text: "Symptom burden", isCorrect: false),
            Option(id: "B", text: "Exacerbation history", isCorrect: false),
            Option(id: "C", text: "Spirometric classification", isCorrect: false),
            Option(id: "D", text: "Oxygen saturation", isCorrect: true),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "True or False: Long-term oxygen therapy (LTOT) is recommended for COPD patients with a resting SpO2 ≤88%.",
          type: QuestionType.trueFalse,
          explanation: "True. Long-term oxygen therapy is typically recommended for COPD patients with resting SpO2 ≤88% or PaO2 ≤55 mmHg, as it has been shown to improve survival in these patients.",
          options: [
            Option(id: "A", text: "True", isCorrect: true),
            Option(id: "B", text: "False", isCorrect: false),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "Which class of medications is associated with increased pneumonia risk in COPD patients?",
          type: QuestionType.multipleChoice,
          explanation: "Inhaled corticosteroids (ICS) have been associated with an increased risk of pneumonia in COPD patients, which is an important consideration in treatment decisions.",
          options: [
            Option(id: "A", text: "Long-acting beta agonists (LABA)", isCorrect: false),
            Option(id: "B", text: "Long-acting muscarinic antagonists (LAMA)", isCorrect: false),
            Option(id: "C", text: "Inhaled corticosteroids (ICS)", isCorrect: true),
            Option(id: "D", text: "Phosphodiesterase-4 inhibitors", isCorrect: false),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "Which of the following interventions have been shown to improve outcomes in COPD? Select all that apply:",
          type: QuestionType.multiSelect,
          explanation: "Smoking cessation, pulmonary rehabilitation, and vaccinations (particularly influenza and pneumococcal) have all been shown to improve outcomes in COPD patients.",
          options: [
            Option(id: "A", text: "Smoking cessation", isCorrect: true),
            Option(id: "B", text: "Pulmonary rehabilitation", isCorrect: true),
            Option(id: "C", text: "Vaccinations", isCorrect: true),
            Option(id: "D", text: "Prophylactic antibiotics for all patients", isCorrect: false),
          ],
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    );
  }

  /// Creates a sample cardiovascular quiz
  static Quiz _createCardiovascularQuiz() {
    return Quiz(
      id: const Uuid().v4(),
      title: "Cardiovascular Risk Assessment",
      description: "Evaluate your knowledge on cardiovascular risk factors, prevention strategies, and treatment approaches.",
      category: QuizCategory.cardiovascular,
      difficulty: QuizDifficulty.advanced,
      timeLimit: 20, // 20 minutes
      questions: [
        Question(
          id: const Uuid().v4(),
          text: "Which of the following is NOT considered a major modifiable risk factor for cardiovascular disease?",
          type: QuestionType.multipleChoice,
          explanation: "While hypertension, smoking, and hyperlipidemia are major modifiable risk factors, family history is a non-modifiable risk factor for cardiovascular disease.",
          options: [
            Option(id: "A", text: "Hypertension", isCorrect: false),
            Option(id: "B", text: "Family history", isCorrect: true),
            Option(id: "C", text: "Smoking", isCorrect: false),
            Option(id: "D", text: "Hyperlipidemia", isCorrect: false),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "According to current guidelines, what is the optimal LDL cholesterol level for patients with established atherosclerotic cardiovascular disease (ASCVD)?",
          type: QuestionType.multipleChoice,
          explanation: "Current guidelines recommend an LDL-C goal of <70 mg/dL for patients with established ASCVD, representing a more aggressive target than previous recommendations.",
          options: [
            Option(id: "A", text: "<100 mg/dL", isCorrect: false),
            Option(id: "B", text: "<70 mg/dL", isCorrect: true),
            Option(id: "C", text: "<130 mg/dL", isCorrect: false),
            Option(id: "D", text: "<55 mg/dL", isCorrect: false),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "True or False: Aspirin is recommended for primary prevention of cardiovascular disease in all adults over 50 years old.",
          type: QuestionType.trueFalse,
          explanation: "False. Recent guidelines have moved away from routine aspirin use for primary prevention due to bleeding risks. Aspirin for primary prevention is now individualized based on specific risk factors and bleeding risk.",
          options: [
            Option(id: "A", text: "True", isCorrect: false),
            Option(id: "B", text: "False", isCorrect: true),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "Which class of medications has been shown to reduce cardiovascular events in patients with type 2 diabetes even in the absence of established cardiovascular disease?",
          type: QuestionType.multipleChoice,
          explanation: "SGLT-2 inhibitors have demonstrated cardiovascular benefits in patients with type 2 diabetes, including those without established cardiovascular disease, reducing major adverse cardiovascular events and heart failure hospitalizations.",
          options: [
            Option(id: "A", text: "DPP-4 inhibitors", isCorrect: false),
            Option(id: "B", text: "Sulfonylureas", isCorrect: false),
            Option(id: "C", text: "SGLT-2 inhibitors", isCorrect: true),
            Option(id: "D", text: "Thiazolidinediones", isCorrect: false),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "Which of the following are components of the ASCVD risk calculator? Select all that apply:",
          type: QuestionType.multiSelect,
          explanation: "The ASCVD risk calculator includes age, total cholesterol, HDL cholesterol, and systolic blood pressure, along with diabetes status, smoking status, and treatment for hypertension.",
          options: [
            Option(id: "A", text: "Age", isCorrect: true),
            Option(id: "B", text: "Total cholesterol", isCorrect: true),
            Option(id: "C", text: "HDL cholesterol", isCorrect: true),
            Option(id: "D", text: "Family history of CVD", isCorrect: false),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "What is the recommended first-line treatment for stable angina?",
          type: QuestionType.multipleChoice,
          explanation: "Beta blockers are recommended as first-line therapy for stable angina due to their ability to reduce heart rate, contractility, and myocardial oxygen demand.",
          options: [
            Option(id: "A", text: "Calcium channel blockers", isCorrect: false),
            Option(id: "B", text: "Beta blockers", isCorrect: true),
            Option(id: "C", text: "Nitrates", isCorrect: false),
            Option(id: "D", text: "Ranolazine", isCorrect: false),
          ],
        ),
        Question(
          id: const Uuid().v4(),
          text: "True or False: Statins can cause muscle-related side effects in some patients.",
          type: QuestionType.trueFalse,
          explanation: "True. Statins can cause muscle-related side effects ranging from myalgia (muscle pain) to more severe but rare conditions like rhabdomyolysis. These side effects are important to monitor and may require medication adjustments.",
          options: [
            Option(id: "A", text: "True", isCorrect: true),
            Option(id: "B", text: "False", isCorrect: false),
          ],
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    );
  }

  /// Returns a sample quiz attempt for testing
  static QuizAttempt getSampleQuizAttempt(String quizId) {
    return QuizAttempt(
      id: const Uuid().v4(),
      quizId: quizId,
      userId: 'user123',
      startTime: DateTime.now().subtract(const Duration(minutes: 15)),
      endTime: DateTime.now(),
      score: 80,
      answers: {
        'q1': ['A'],
        'q2': ['B'],
        'q3': ['A', 'C'],
      },
      completed: true,
    );
  }
}