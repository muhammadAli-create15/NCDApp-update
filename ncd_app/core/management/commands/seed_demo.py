from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from django.utils import timezone
from core.models import (
	PatientProfile,
	HealthRecord,
	DeviceReading,
	Medication,
	Appointment,
	EducationContent,
	SupportGroup,
	SupportGroupMessage,
	ProviderAssignment,
	WorkerAssignment,
	QuestionnaireResponse,
    QuestionnaireTemplate,
    Quiz,
    QuizQuestion,
)
from django.db import transaction

class Command(BaseCommand):
	help = "Seed demo data for NCD app (patients, readings, meds, appointments, education, support groups)"

	def handle(self, *args, **options):
		# Users
		patient_user, _ = User.objects.get_or_create(username='demo_patient', defaults={'email': 'patient@example.com'})
		patient_user.set_password('Str0ngPass!')
		patient_user.save()
		provider_user, _ = User.objects.get_or_create(username='demo_provider', defaults={'email': 'provider@example.com'})
		provider_user.set_password('Str0ngPass!')
		provider_user.save()
		worker_user, _ = User.objects.get_or_create(username='demo_worker', defaults={'email': 'worker@example.com'})
		worker_user.set_password('Str0ngPass!')
		worker_user.save()

		patient, _ = PatientProfile.objects.get_or_create(user=patient_user, defaults={
			'role': 'patient', 'age': 45, 'gender': 'male', 'height_cm': 175, 'weight_kg': 82, 'waist_cm': 96,
			'phone': '0700000000', 'address': 'Demo street', 'lifestyle': 'sedentary'
		})
		provider, _ = PatientProfile.objects.get_or_create(user=provider_user, defaults={
			'role': 'provider', 'age': 38, 'gender': 'female', 'height_cm': 165, 'weight_kg': 62, 'waist_cm': 72
		})
		worker, _ = PatientProfile.objects.get_or_create(user=worker_user, defaults={
			'role': 'worker', 'age': 29, 'gender': 'female', 'height_cm': 160, 'weight_kg': 60, 'waist_cm': 70
		})

		ProviderAssignment.objects.get_or_create(provider=provider, patient=patient)
		WorkerAssignment.objects.get_or_create(worker=worker, patient=patient)

		# Health record (for risk and recommendations)
		HealthRecord.objects.get_or_create(patient=patient, defaults={
			'blood_pressure_systolic': 148,
			'blood_pressure_diastolic': 92,
			'blood_glucose': 185,
			'bmi': 26.8,
		})

		# Device readings (for analytics and lists)
		for i in range(5):
			DeviceReading.objects.get_or_create(patient=patient, reading_type='glucose', value=110 + i * 8, unit='mg/dL', recorded_at=timezone.now())
			DeviceReading.objects.get_or_create(patient=patient, reading_type='bp', value=0, unit='mmHg', systolic=130 + i, diastolic=84 + i, recorded_at=timezone.now())

		# Medications
		Medication.objects.get_or_create(patient=patient, name='Metformin', dosage='500mg', frequency='BID', reminder_time='08:00:00')
		Medication.objects.get_or_create(patient=patient, name='Amlodipine', dosage='5mg', frequency='OD', reminder_time='20:00:00')

		# Appointments
		Appointment.objects.get_or_create(patient=patient, title='Clinic Visit', scheduled_for=timezone.now() + timezone.timedelta(days=7))

		# Education content
		EducationContent.objects.get_or_create(title='Low-salt diet basics', topic='diet', content='Reduce sodium intake to <5g/day.')
		EducationContent.objects.get_or_create(title='30-minute brisk walk', topic='exercise', content='Aim for 150 minutes per week.')

		# Support group and sample message
		group, _ = SupportGroup.objects.get_or_create(name='Diabetes Support')
		group.members.add(patient)
		SupportGroupMessage.objects.get_or_create(group=group, author=patient, message='Hello everyone!')

		# WHO STEPS-like questionnaire samples
		QuestionnaireResponse.objects.get_or_create(patient=patient, category='lifestyle', answers={
			'smoke': False,
			'alcohol_days_per_week': 1,
			'fruit_veg_servings_per_day': 3,
			'family_history_diabetes': True,
			'physical_activity_minutes_per_day': 30,
		})

		# Quizzes (education & adherence)
		dm_quiz, _ = Quiz.objects.get_or_create(title='Diabetes Self-care Basics', topic='diabetes')
		QuizQuestion.objects.get_or_create(
			quiz=dm_quiz,
			text='Which food choice is best for stable blood glucose?',
			defaults={'choices': ['Sugary drink', 'White bread', 'Whole grains/vegetables', 'Candy'], 'correct_index': 2}
		)
		QuizQuestion.objects.get_or_create(
			quiz=dm_quiz,
			text='What is a common sign of hypoglycemia?',
			defaults={'choices': ['Excessive thirst', 'Shaking/sweating', 'Frequent urination', 'Blurred vision only'], 'correct_index': 1}
		)
		QuizQuestion.objects.get_or_create(
			quiz=dm_quiz,
			text='How many minutes of moderate activity per week are recommended?',
			defaults={'choices': ['30', '60', '150', '300'], 'correct_index': 2}
		)

		htn_quiz, _ = Quiz.objects.get_or_create(title='Hypertension Management', topic='hypertension')
		QuizQuestion.objects.get_or_create(
			quiz=htn_quiz,
			text='Target daily salt intake for most adults is:',
			defaults={'choices': ['< 5g', '10-15g', 'No limit', 'Only after exercise'], 'correct_index': 0}
		)
		QuizQuestion.objects.get_or_create(
			quiz=htn_quiz,
			text='When to seek urgent care for BP?',
			defaults={'choices': ['160/100', '180/120 with symptoms', '140/90 for 1 day', '130/80 after exercise'], 'correct_index': 1}
		)
		QuizQuestion.objects.get_or_create(
			quiz=htn_quiz,
			text='Which lifestyle change most lowers BP?',
			defaults={'choices': ['More sugar', 'Less salt/DASH diet', 'Skip medications', 'Smoke occasionally'], 'correct_index': 1}
		)

		# WHO STEPS-like templates
		QuestionnaireTemplate.objects.get_or_create(name='Lifestyle', category='lifestyle', defaults={
			'schema': {
				'title': 'Lifestyle',
				'properties': {
					'smoke': {'type': 'boolean'},
					'alcohol_days_per_week': {'type': 'integer', 'minimum': 0, 'maximum': 7},
					'physical_activity_minutes_per_day': {'type': 'integer', 'minimum': 0, 'maximum': 600}
				},
				'required': ['smoke']
			}
		})
		QuestionnaireTemplate.objects.get_or_create(name='Diet', category='diet', defaults={
			'schema': {
				'title': 'Diet',
				'properties': {
					'fruit_veg_servings_per_day': {'type': 'integer', 'minimum': 0, 'maximum': 10},
					'salt_intake_level': {'type': 'string', 'enum': ['low','moderate','high']}
				},
				'required': ['fruit_veg_servings_per_day']
			}
		})
		QuestionnaireTemplate.objects.get_or_create(name='Family history', category='family', defaults={
			'schema': {
				'title': 'Family history',
				'properties': {
					'family_history_diabetes': {'type': 'boolean'},
					'family_history_hypertension': {'type': 'boolean'}
				}
			}
		})

		self.stdout.write(self.style.SUCCESS('Demo data seeded. Users: demo_patient / demo_provider / demo_worker (password: Str0ngPass!)'))
