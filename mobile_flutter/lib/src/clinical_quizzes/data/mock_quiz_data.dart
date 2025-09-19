import 'package:uuid/uuid.dart';
import '../models/models.dart';

/// Provides mock quiz data for testing and development purposes
class MockQuizData {
  /// Returns a list of sample quizzes covering different NCD topics
  static List<Quiz> getSampleQuizzes() {
    return [
      _createDiabetesQuiz(),
      _createHypertensionQuiz(),
      _createRespiratoryQuiz(),
      _createKidneyQuiz(),
      _createCardiovascularQuiz(),
    ];
  }

  /// Creates a sample diabetes quiz
  static Quiz _createDiabetesQuiz() {
    return Quiz(
      quizId: 'diabetes_management_2023',
      title: "Diabetes Management",
      description: "Test your knowledge on current diabetes management guidelines and treatment options.",
      category: QuizCategory.diabetes,
      difficulty: QuizDifficulty.intermediate,
      version: '1.0',
      passingScore: 70,
      questions: [
        Question(
          questionId: 'dm_q1',
          text: "What is the recommended HbA1c target for most adults with diabetes?",
          type: QuestionType.multipleChoiceSingleAnswer,
          explanation: "Clinical guidelines recommend an HbA1c target of <7% for most adults with diabetes, though targets may be individualized based on patient factors.",
          options: [
            Option(value: "A", displayText: "<6.5%", isCorrect: false),
            Option(value: "B", displayText: "<7%", isCorrect: true),
            Option(value: "C", displayText: "<8%", isCorrect: false),
            Option(value: "D", displayText: "<9%", isCorrect: false),
          ],
        ),
        Question(
          questionId: 'dm_q2',
          text: "Which of the following is NOT a first-line medication for type 2 diabetes according to current guidelines?",
          type: QuestionType.multipleChoiceSingleAnswer,
          explanation: "Metformin is the first-line medication for type 2 diabetes. SGLT-2 inhibitors, GLP-1 receptor agonists, and DPP-4 inhibitors are typically second or third-line options, with insulin being used when other options fail or in specific circumstances.",
          options: [
            Option(value: "A", displayText: "Metformin", isCorrect: false),
            Option(value: "B", displayText: "SGLT-2 inhibitor", isCorrect: false),
            Option(value: "C", displayText: "Insulin", isCorrect: true),
            Option(value: "D", displayText: "GLP-1 receptor agonist", isCorrect: false),
          ],
        ),
        Question(
          questionId: 'dm_q3',
          text: "Which of the following is a key component of diabetes self-management education?",
          type: QuestionType.multipleChoiceSingleAnswer,
          explanation: "All options are important components of diabetes self-management education, but regular blood glucose monitoring is particularly critical as it allows patients to track their glycemic control and adjust behaviors accordingly.",
          options: [
            Option(value: "A", displayText: "Regular blood glucose monitoring", isCorrect: true),
            Option(value: "B", displayText: "Exercise planning", isCorrect: false),
            Option(value: "C", displayText: "Meal planning", isCorrect: false),
            Option(value: "D", displayText: "Foot care education", isCorrect: false),
          ],
        ),
        Question(
          questionId: 'dm_q4',
          text: "What is the primary mechanism of action of SGLT-2 inhibitors?",
          type: QuestionType.multipleChoiceSingleAnswer,
          explanation: "SGLT-2 inhibitors work by inhibiting sodium-glucose cotransporter-2 in the proximal renal tubules, which reduces glucose reabsorption and increases urinary glucose excretion.",
          options: [
            Option(value: "A", displayText: "Increase insulin secretion from pancreatic beta cells", isCorrect: false),
            Option(value: "B", displayText: "Decrease glucose production in the liver", isCorrect: false),
            Option(value: "C", displayText: "Increase glucose uptake in muscle cells", isCorrect: false),
            Option(value: "D", displayText: "Increase glucose excretion in urine", isCorrect: true),
          ],
        ),
        Question(
          questionId: 'dm_q5',
          text: "Select all complications that are associated with uncontrolled diabetes:",
          type: QuestionType.multipleChoiceMultipleAnswer,
          explanation: "Uncontrolled diabetes can lead to multiple complications including nephropathy (kidney disease), retinopathy (eye damage), neuropathy (nerve damage), and cardiovascular disease.",
          options: [
            Option(value: "A", displayText: "Diabetic nephropathy", isCorrect: true),
            Option(value: "B", displayText: "Diabetic retinopathy", isCorrect: true),
            Option(value: "C", displayText: "Peripheral neuropathy", isCorrect: true),
            Option(value: "D", displayText: "Hypertrichosis", isCorrect: false),
          ],
        ),
      ],
    );
  }

  /// Creates a sample hypertension quiz
  static Quiz _createHypertensionQuiz() {
    return Quiz(
      quizId: 'hypertension_guidelines_2023',
      title: "Hypertension Assessment",
      description: "Review your knowledge on hypertension diagnosis and treatment protocols.",
      category: QuizCategory.hypertension,
      difficulty: QuizDifficulty.beginner,
      version: '1.0',
      passingScore: 70,
      questions: [
        Question(
          questionId: 'htn_q1',
          text: "According to current guidelines, at what blood pressure threshold is hypertension diagnosed?",
          type: QuestionType.multipleChoiceSingleAnswer,
          explanation: "According to most current guidelines, hypertension is diagnosed at BP ≥130/80 mmHg, which was lowered from the previous threshold of 140/90 mmHg.",
          options: [
            Option(value: "A", displayText: "≥120/70 mmHg", isCorrect: false),
            Option(value: "B", displayText: "≥130/80 mmHg", isCorrect: true),
            Option(value: "C", displayText: "≥140/90 mmHg", isCorrect: false),
            Option(value: "D", displayText: "≥150/95 mmHg", isCorrect: false),
          ],
        ),
        Question(
          questionId: 'htn_q2',
          text: "Which class of antihypertensive medications is contraindicated in pregnancy?",
          type: QuestionType.multipleChoiceSingleAnswer,
          explanation: "ACE inhibitors and ARBs are contraindicated during pregnancy due to the risk of fetal renal damage and other developmental abnormalities.",
          options: [
            Option(value: "A", displayText: "Calcium channel blockers", isCorrect: false),
            Option(value: "B", displayText: "ACE inhibitors", isCorrect: true),
            Option(value: "C", displayText: "Beta blockers", isCorrect: false),
            Option(value: "D", displayText: "Thiazide diuretics", isCorrect: false),
          ],
        ),
        Question(
          questionId: 'htn_q3',
          text: "What is the recommended blood pressure target for patients with diabetes?",
          type: QuestionType.multipleChoiceSingleAnswer,
          explanation: "For patients with diabetes, current guidelines recommend a blood pressure target of <130/80 mmHg to reduce the risk of cardiovascular events and microvascular complications.",
          options: [
            Option(value: "A", displayText: "<130/80 mmHg", isCorrect: true),
            Option(value: "B", displayText: "<140/90 mmHg", isCorrect: false),
            Option(value: "C", displayText: "<150/90 mmHg", isCorrect: false),
            Option(value: "D", displayText: "<120/70 mmHg", isCorrect: false),
          ],
        ),
        Question(
          questionId: 'htn_q4',
          text: "True or False: White coat hypertension has no clinical significance and requires no follow-up.",
          type: QuestionType.multipleChoiceSingleAnswer,
          explanation: "False. While white coat hypertension (elevated BP only in clinical settings) was once thought to be benign, recent evidence suggests it may be associated with increased cardiovascular risk and should be monitored.",
          options: [
            Option(value: "A", displayText: "True", isCorrect: false),
            Option(value: "B", displayText: "False", isCorrect: true),
          ],
        ),
        Question(
          questionId: 'htn_q5',
          text: "Which of these lifestyle modifications have been proven to reduce blood pressure? Select all that apply:",
          type: QuestionType.multipleChoiceMultipleAnswer,
          explanation: "The DASH diet, regular physical activity, and sodium restriction have all been proven in clinical studies to reduce blood pressure. Stress management techniques may also help.",
          options: [
            Option(value: "A", displayText: "DASH diet", isCorrect: true),
            Option(value: "B", displayText: "Regular physical activity", isCorrect: true),
            Option(value: "C", displayText: "Sodium restriction", isCorrect: true),
            Option(value: "D", displayText: "Increased caffeine intake", isCorrect: false),
          ],
        ),
      ],
    );
  }

  /// Creates a sample respiratory quiz covering asthma and COPD
  static Quiz _createRespiratoryQuiz() {
    return Quiz(
      quizId: 'respiratory_disorders_2023',
      title: "Respiratory Disorders Management",
      description: "Test your knowledge of asthma and COPD diagnosis, classification, and treatment strategies.",
      category: QuizCategory.generalNcd,
      difficulty: QuizDifficulty.intermediate,
      version: '1.0',
      passingScore: 75,
      questions: [
        Question(
          questionId: 'resp_q1',
          text: "Which of the following is NOT a typical symptom of asthma?",
          type: QuestionType.multipleChoiceSingleAnswer,
          explanation: "While wheezing, coughing, and shortness of breath are classic asthma symptoms, chest pain is not typically a primary symptom of asthma and may indicate other conditions.",
          options: [
            Option(value: "A", displayText: "Wheezing", isCorrect: false),
            Option(value: "B", displayText: "Coughing", isCorrect: false),
            Option(value: "C", displayText: "Chest pain", isCorrect: true),
            Option(value: "D", displayText: "Shortness of breath", isCorrect: false),
          ],
        ),
        Question(
          questionId: 'resp_q2',
          text: "Which medication class is considered first-line controller therapy for persistent asthma?",
          type: QuestionType.multipleChoiceSingleAnswer,
          explanation: "Inhaled corticosteroids (ICS) are the gold standard first-line controller medication for persistent asthma due to their efficacy in reducing airway inflammation.",
          options: [
            Option(value: "A", displayText: "Short-acting beta agonists (SABA)", isCorrect: false),
            Option(value: "B", displayText: "Inhaled corticosteroids (ICS)", isCorrect: true),
            Option(value: "C", displayText: "Leukotriene modifiers", isCorrect: false),
            Option(value: "D", displayText: "Long-acting beta agonists (LABA) alone", isCorrect: false),
          ],
        ),
        Question(
          questionId: 'resp_q3',
          text: "True or False: Spirometry can be used to confirm an asthma diagnosis.",
          type: QuestionType.multipleChoiceSingleAnswer,
          explanation: "True. Spirometry showing reversible airflow obstruction (improvement in FEV1 ≥12% and ≥200 mL after bronchodilator) supports an asthma diagnosis.",
          options: [
            Option(value: "A", displayText: "True", isCorrect: true),
            Option(value: "B", displayText: "False", isCorrect: false),
          ],
        ),
        Question(
          questionId: 'resp_q4',
          text: "Which spirometry result is required for a diagnosis of COPD?",
          type: QuestionType.multipleChoiceSingleAnswer,
          explanation: "A post-bronchodilator FEV1/FVC ratio <0.7 is the spirometric criterion for COPD diagnosis according to GOLD guidelines.",
          options: [
            Option(value: "A", displayText: "FEV1 <80% predicted", isCorrect: false),
            Option(value: "B", displayText: "FEV1/FVC ratio <0.7", isCorrect: true),
            Option(value: "C", displayText: "FVC <80% predicted", isCorrect: false),
            Option(value: "D", displayText: "TLC >120% predicted", isCorrect: false),
          ],
        ),
        Question(
          questionId: 'resp_q5',
          text: "Which of the following interventions have been shown to improve outcomes in COPD? Select all that apply:",
          type: QuestionType.multipleChoiceMultipleAnswer,
          explanation: "Smoking cessation, pulmonary rehabilitation, and vaccinations (particularly influenza and pneumococcal) have all been shown to improve outcomes in COPD patients.",
          options: [
            Option(value: "A", displayText: "Smoking cessation", isCorrect: true),
            Option(value: "B", displayText: "Pulmonary rehabilitation", isCorrect: true),
            Option(value: "C", displayText: "Vaccinations", isCorrect: true),
            Option(value: "D", displayText: "Prophylactic antibiotics for all patients", isCorrect: false),
          ],
        ),
      ],
    );
  }

  /// Creates a sample kidney disease quiz
  static Quiz _createKidneyQuiz() {
    return Quiz(
      quizId: 'kidney_disease_advanced',
      title: "Advanced CKD Management",
      description: "Advanced topics in chronic kidney disease management for specialists.",
      category: QuizCategory.kidney,
      difficulty: QuizDifficulty.advanced,
      version: '1.0',
      passingScore: 75,
      maxAttempts: 3,
      questions: [
        Question(
          questionId: 'ckd_q1',
          text: "A 67-year-old patient has an eGFR of 25 mL/min/1.73m² and albuminuria of 500 mg/g. According to the KDIGO classification, what stage of CKD does this represent?",
          type: QuestionType.multipleChoiceSingleAnswer,
          explanation: "According to the KDIGO classification, an eGFR of 25 mL/min/1.73m² corresponds to Stage 4 CKD (eGFR 15-29 mL/min/1.73m²). Albuminuria of 500 mg/g is classified as A3 (>300 mg/g). Therefore, this patient has Stage 4, A3 CKD, which represents a high risk for progression to kidney failure and cardiovascular events.",
          options: [
            Option(value: "A", displayText: "Stage 3a, A3", isCorrect: false),
            Option(value: "B", displayText: "Stage 3b, A3", isCorrect: false),
            Option(value: "C", displayText: "Stage 4, A3", isCorrect: true),
            Option(value: "D", displayText: "Stage 5, A2", isCorrect: false),
          ],
        ),
        Question(
          questionId: 'ckd_q2',
          text: "Which of the following interventions have been shown to slow the progression of diabetic kidney disease? Select all that apply.",
          type: QuestionType.multipleChoiceMultipleAnswer,
          explanation: "SGLT2 inhibitors have shown significant renal benefits in multiple trials (CREDENCE, DAPA-CKD). ACE inhibitors and ARBs reduce albuminuria and slow progression of diabetic kidney disease. Finerenone, a non-steroidal mineralocorticoid receptor antagonist, has been shown to reduce CKD progression in the FIDELIO-DKD trial. Very intensive glucose control has not consistently shown benefits and carries hypoglycemia risks. High-protein diets may actually accelerate CKD progression and are typically not recommended.",
          options: [
            Option(value: "A", displayText: "SGLT2 inhibitors", isCorrect: true),
            Option(value: "B", displayText: "ACE inhibitors or ARBs", isCorrect: true),
            Option(value: "C", displayText: "Finerenone", isCorrect: true),
            Option(value: "D", displayText: "Intensive glucose control (HbA1c <6.5%)", isCorrect: false),
            Option(value: "E", displayText: "High-protein diet", isCorrect: false),
          ],
        ),
      ],
    );
  }

  /// Creates a sample cardiovascular quiz
  static Quiz _createCardiovascularQuiz() {
    return Quiz(
      quizId: 'cardio_risk_assessment',
      title: "Cardiovascular Risk Assessment",
      description: "Evaluate your knowledge on cardiovascular risk factors, prevention strategies, and treatment approaches.",
      category: QuizCategory.generalNcd,
      difficulty: QuizDifficulty.advanced,
      version: '1.0',
      passingScore: 80,
      questions: [
        Question(
          questionId: 'cv_q1',
          text: "Which of the following is NOT considered a major modifiable risk factor for cardiovascular disease?",
          type: QuestionType.multipleChoiceSingleAnswer,
          explanation: "While hypertension, smoking, and hyperlipidemia are major modifiable risk factors, family history is a non-modifiable risk factor for cardiovascular disease.",
          options: [
            Option(value: "A", displayText: "Hypertension", isCorrect: false),
            Option(value: "B", displayText: "Family history", isCorrect: true),
            Option(value: "C", displayText: "Smoking", isCorrect: false),
            Option(value: "D", displayText: "Hyperlipidemia", isCorrect: false),
          ],
        ),
        Question(
          questionId: 'cv_q2',
          text: "According to current guidelines, what is the optimal LDL cholesterol level for patients with established atherosclerotic cardiovascular disease (ASCVD)?",
          type: QuestionType.multipleChoiceSingleAnswer,
          explanation: "Current guidelines recommend an LDL-C goal of <70 mg/dL for patients with established ASCVD, representing a more aggressive target than previous recommendations.",
          options: [
            Option(value: "A", displayText: "<100 mg/dL", isCorrect: false),
            Option(value: "B", displayText: "<70 mg/dL", isCorrect: true),
            Option(value: "C", displayText: "<130 mg/dL", isCorrect: false),
            Option(value: "D", displayText: "<55 mg/dL", isCorrect: false),
          ],
        ),
        Question(
          questionId: 'cv_q3',
          text: "True or False: Aspirin is recommended for primary prevention of cardiovascular disease in all adults over 50 years old.",
          type: QuestionType.multipleChoiceSingleAnswer,
          explanation: "False. Recent guidelines have moved away from routine aspirin use for primary prevention due to bleeding risks. Aspirin for primary prevention is now individualized based on specific risk factors and bleeding risk.",
          options: [
            Option(value: "A", displayText: "True", isCorrect: false),
            Option(value: "B", displayText: "False", isCorrect: true),
          ],
        ),
        Question(
          questionId: 'cv_q4',
          text: "Which class of medications has been shown to reduce cardiovascular events in patients with type 2 diabetes even in the absence of established cardiovascular disease?",
          type: QuestionType.multipleChoiceSingleAnswer,
          explanation: "SGLT-2 inhibitors have demonstrated cardiovascular benefits in patients with type 2 diabetes, including those without established cardiovascular disease, reducing major adverse cardiovascular events and heart failure hospitalizations.",
          options: [
            Option(value: "A", displayText: "DPP-4 inhibitors", isCorrect: false),
            Option(value: "B", displayText: "Sulfonylureas", isCorrect: false),
            Option(value: "C", displayText: "SGLT-2 inhibitors", isCorrect: true),
            Option(value: "D", displayText: "Thiazolidinediones", isCorrect: false),
          ],
        ),
        Question(
          questionId: 'cv_q5',
          text: "Which of the following are components of the ASCVD risk calculator? Select all that apply:",
          type: QuestionType.multipleChoiceMultipleAnswer,
          explanation: "The ASCVD risk calculator includes age, total cholesterol, HDL cholesterol, and systolic blood pressure, along with diabetes status, smoking status, and treatment for hypertension.",
          options: [
            Option(value: "A", displayText: "Age", isCorrect: true),
            Option(value: "B", displayText: "Total cholesterol", isCorrect: true),
            Option(value: "C", displayText: "HDL cholesterol", isCorrect: true),
            Option(value: "D", displayText: "Family history of CVD", isCorrect: false),
          ],
        ),
      ],
    );
  }

  /// Returns a sample quiz attempt for testing
  static QuizAttempt getSampleQuizAttempt(String quizId) {
    return QuizAttempt(
      attemptId: const Uuid().v4(),
      userId: 'user123',
      quizId: quizId,
      dateStarted: DateTime.now().subtract(const Duration(minutes: 15)),
      dateCompleted: DateTime.now(),
      chosenAnswers: {
        'dm_q1': ['B'],
        'dm_q2': ['C'],
        'dm_q3': ['A'],
      },
      score: 80,
      passed: true,
    );
  }
}