from django.contrib.auth.models import User
from django.db import models
from django.utils import timezone

class PatientProfile(models.Model):
    ROLE_CHOICES = (
        ('patient', 'Patient'),
        ('provider', 'Provider'),
        ('worker', 'Community Health Worker'),
    )

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='patient_profile')
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='patient')
    phone = models.CharField(max_length=20, blank=True)
    address = models.TextField(blank=True)
    age = models.IntegerField()
    gender = models.CharField(max_length=10)
    height_cm = models.FloatField()
    weight_kg = models.FloatField()
    waist_cm = models.FloatField()
    lifestyle = models.TextField(blank=True)

    def __str__(self):
        return f"{self.user.username}'s profile"

    class Meta:
        verbose_name_plural = "Patient Profiles"

class HealthRecord(models.Model):
    patient = models.ForeignKey(PatientProfile, on_delete=models.CASCADE)
    blood_pressure_systolic = models.IntegerField()
    blood_pressure_diastolic = models.IntegerField()
    blood_glucose = models.FloatField()
    bmi = models.FloatField()
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Record for {self.patient.user.username} at {self.timestamp.strftime('%Y-%m-%d %H:%M')}"

class Medication(models.Model):
    patient = models.ForeignKey(PatientProfile, on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    dosage = models.CharField(max_length=50)
    frequency = models.CharField(max_length=50)
    reminder_time = models.TimeField()

    def __str__(self):
        return f"{self.name} for {self.patient.user.username}"

# ----------------------
# Extended domain models
# ----------------------

class ProviderAssignment(models.Model):
    """Maps a provider to a patient for access and care coordination."""
    provider = models.ForeignKey(PatientProfile, on_delete=models.CASCADE, related_name='assigned_patients')
    patient = models.ForeignKey(PatientProfile, on_delete=models.CASCADE, related_name='assigned_providers')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('provider', 'patient')

    def __str__(self):
        return f"{self.provider.user.username} -> {self.patient.user.username}"


class QuestionnaireResponse(models.Model):
    """Stores patient questionnaire submissions (family history, lifestyle, etc.)."""
    patient = models.ForeignKey(PatientProfile, on_delete=models.CASCADE)
    category = models.CharField(max_length=100)  # e.g., lifestyle, family_history
    answers = models.JSONField()
    submitted_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Questionnaire {self.category} by {self.patient.user.username}"


class DeviceReading(models.Model):
    """Generic device reading (e.g., glucometer, BP monitor)."""
    READING_TYPES = (
        ('glucose', 'Blood Glucose'),
        ('bp', 'Blood Pressure'),
        ('weight', 'Weight'),
        ('bmi', 'BMI'),
        ('waist', 'Waist Circumference'),
    )
    patient = models.ForeignKey(PatientProfile, on_delete=models.CASCADE)
    reading_type = models.CharField(max_length=20, choices=READING_TYPES)
    value = models.FloatField()
    unit = models.CharField(max_length=20)
    systolic = models.IntegerField(null=True, blank=True)
    diastolic = models.IntegerField(null=True, blank=True)
    source = models.CharField(max_length=50, default='manual')  # manual/bluetooth/api
    recorded_at = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f"{self.reading_type}={self.value} {self.unit} for {self.patient.user.username}"


class Alert(models.Model):
    """Clinical or system alerts (e.g., critical BP, hypo/hyperglycemia)."""
    SEVERITY_CHOICES = (
        ('info', 'Info'),
        ('warning', 'Warning'),
        ('critical', 'Critical'),
    )
    patient = models.ForeignKey(PatientProfile, on_delete=models.CASCADE)
    alert_type = models.CharField(max_length=50)
    message = models.TextField()
    severity = models.CharField(max_length=10, choices=SEVERITY_CHOICES, default='info')
    created_at = models.DateTimeField(auto_now_add=True)
    resolved = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.severity.upper()} - {self.alert_type} for {self.patient.user.username}"


class Appointment(models.Model):
    """Appointments and lab tests scheduling/reminders."""
    STATUS_CHOICES = (
        ('scheduled', 'Scheduled'),
        ('completed', 'Completed'),
        ('missed', 'Missed'),
        ('cancelled', 'Cancelled'),
    )
    patient = models.ForeignKey(PatientProfile, on_delete=models.CASCADE)
    title = models.CharField(max_length=100)  # e.g., Clinic visit, HbA1c test
    scheduled_for = models.DateTimeField()
    notes = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='scheduled')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.title} for {self.patient.user.username} on {self.scheduled_for}"


class EducationContent(models.Model):
    """Short educational items (text, link to video/infographic)."""
    TOPIC_CHOICES = (
        ('diet', 'Diet'),
        ('exercise', 'Exercise'),
        ('stress', 'Stress Management'),
        ('general', 'General'),
    )
    title = models.CharField(max_length=150)
    topic = models.CharField(max_length=20, choices=TOPIC_CHOICES, default='general')
    content = models.TextField(blank=True)
    media_url = models.URLField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title


class SupportGroup(models.Model):
    name = models.CharField(max_length=120)
    description = models.TextField(blank=True)
    members = models.ManyToManyField(PatientProfile, related_name='support_groups', blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class SupportGroupMessage(models.Model):
    group = models.ForeignKey(SupportGroup, on_delete=models.CASCADE, related_name='messages')
    author = models.ForeignKey(PatientProfile, on_delete=models.CASCADE)
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Msg by {self.author.user.username} in {self.group.name}"


# ----------------------
# Devices and push tokens
# ----------------------

class Device(models.Model):
    DEVICE_TYPES = (
        ('glucometer', 'Glucometer'),
        ('bp_monitor', 'Blood Pressure Monitor'),
        ('scale', 'Scale'),
        ('other', 'Other'),
    )
    patient = models.ForeignKey(PatientProfile, on_delete=models.CASCADE)
    device_type = models.CharField(max_length=20, choices=DEVICE_TYPES)
    name = models.CharField(max_length=100)
    identifier = models.CharField(max_length=120, unique=True)
    last_sync = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"{self.name} ({self.device_type})"


class PushDevice(models.Model):
    PLATFORM_CHOICES = (
        ('android', 'Android'),
        ('ios', 'iOS'),
    )
    user = models.ForeignKey('auth.User', on_delete=models.CASCADE)
    token = models.CharField(max_length=255, unique=True)
    platform = models.CharField(max_length=20, choices=PLATFORM_CHOICES)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.platform} token for {self.user.username}"


# ----------------------
# Consents and templates
# ----------------------

class DataShareConsent(models.Model):
    """Patient consents to allow a provider to access/export their data."""
    patient = models.ForeignKey(PatientProfile, on_delete=models.CASCADE, related_name='consents_given')
    provider = models.ForeignKey(PatientProfile, on_delete=models.CASCADE, related_name='consents_received')
    granted = models.BooleanField(default=False)
    granted_at = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('patient', 'provider')

    def __str__(self):
        state = 'granted' if self.granted else 'revoked'
        return f"Consent {state}: {self.patient.user.username} -> {self.provider.user.username}"


class QuestionnaireTemplate(models.Model):
    """Defines reusable questionnaire templates to be filled by patients."""
    name = models.CharField(max_length=120)
    category = models.CharField(max_length=100, default='general')
    schema = models.JSONField(help_text='JSON Schema-like structure for questions')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


# ----------------------
# Lab tests and quizzes
# ----------------------

class LabTest(models.Model):
    TEST_TYPES = (
        ('hba1c', 'HbA1c'),
        ('lipids', 'Lipid Profile'),
        ('fbg', 'Fasting Blood Glucose'),
        ('rbg', 'Random Blood Glucose'),
        ('creatinine', 'Creatinine'),
        ('other', 'Other'),
    )
    patient = models.ForeignKey(PatientProfile, on_delete=models.CASCADE)
    test_type = models.CharField(max_length=30, choices=TEST_TYPES, default='other')
    result_value = models.FloatField(null=True, blank=True)
    unit = models.CharField(max_length=20, blank=True)
    taken_on = models.DateTimeField(default=timezone.now)
    notes = models.TextField(blank=True)

    def __str__(self):
        return f"{self.test_type} for {self.patient.user.username}"


class Quiz(models.Model):
    title = models.CharField(max_length=150)
    topic = models.CharField(max_length=50, default='general')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title


class QuizQuestion(models.Model):
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE, related_name='questions')
    text = models.CharField(max_length=300)
    choices = models.JSONField(default=list)  # ["A", "B", "C", ...]
    correct_index = models.IntegerField(default=0)

    def __str__(self):
        return f"Q: {self.text[:30]}..."


class QuizResponse(models.Model):
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE)
    patient = models.ForeignKey(PatientProfile, on_delete=models.CASCADE)
    answers = models.JSONField(default=list)  # [1, 0, 3]
    score = models.IntegerField(default=0)
    submitted_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Resp by {self.patient.user.username} on {self.quiz.title}"


# ----------------------
# Direct messaging & audit log
# ----------------------

class DirectMessage(models.Model):
    sender = models.ForeignKey(PatientProfile, on_delete=models.CASCADE, related_name='dm_sent')
    recipient = models.ForeignKey(PatientProfile, on_delete=models.CASCADE, related_name='dm_received')
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    read = models.BooleanField(default=False)

    def __str__(self):
        return f"DM {self.sender.user.username} -> {self.recipient.user.username}"


class AuditLog(models.Model):
    ACTIONS = (
        ('create', 'Create'),
        ('update', 'Update'),
        ('delete', 'Delete'),
    )
    user = models.ForeignKey('auth.User', on_delete=models.SET_NULL, null=True, blank=True)
    model = models.CharField(max_length=120)
    object_id = models.CharField(max_length=120)
    action = models.CharField(max_length=10, choices=ACTIONS)
    timestamp = models.DateTimeField(auto_now_add=True)
    changes = models.JSONField(null=True, blank=True)

    def __str__(self):
        return f"{self.action} {self.model}:{self.object_id} by {self.user}"


class WorkerAssignment(models.Model):
    """Assigns community health workers to patients."""
    worker = models.ForeignKey(PatientProfile, on_delete=models.CASCADE, related_name='assigned_patients_as_worker')
    patient = models.ForeignKey(PatientProfile, on_delete=models.CASCADE, related_name='assigned_workers')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('worker', 'patient')

    def __str__(self):
        return f"{self.worker.user.username} -> {self.patient.user.username}"
