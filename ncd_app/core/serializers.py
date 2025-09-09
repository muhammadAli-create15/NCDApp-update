from rest_framework import serializers
from .models import (
    PatientProfile,
    HealthRecord,
    Medication,
    QuestionnaireResponse,
    DeviceReading,
    Alert,
    Appointment,
    EducationContent,
    SupportGroup,
    SupportGroupMessage,
    ProviderAssignment,
    Device,
    PushDevice,
    DataShareConsent,
    QuestionnaireTemplate,
    LabTest,
    Quiz,
    QuizQuestion,
    QuizResponse,
    DirectMessage,
    AuditLog,
    WorkerAssignment,
)
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError

class PatientProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = PatientProfile
        fields = '__all__'

class HealthRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = HealthRecord
        fields = '__all__'

class MedicationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Medication
        fields = '__all__'

# ✅ New serializer for registration
class RegisterSerializer(serializers.ModelSerializer):
    age = serializers.IntegerField()
    gender = serializers.CharField()
    height_cm = serializers.FloatField()
    weight_kg = serializers.FloatField()
    waist_cm = serializers.FloatField()
    role = serializers.ChoiceField(choices=PatientProfile.ROLE_CHOICES, default='patient')
    phone = serializers.CharField(required=False, allow_blank=True)
    address = serializers.CharField(required=False, allow_blank=True)
    lifestyle = serializers.CharField(required=False, allow_blank=True)

    class Meta:
        model = User
        fields = [
            'username', 'email', 'password',
            'age', 'gender', 'height_cm', 'weight_kg', 'waist_cm',
            'role', 'phone', 'address', 'lifestyle'
        ]
        extra_kwargs = {'password': {'write_only': True}}

    def validate_password(self, value):
        try:
            validate_password(value)
        except ValidationError as e:
            raise serializers.ValidationError(e.messages)
        return value

    def create(self, validated_data):
        profile_data = {
            'age': validated_data.pop('age'),
            'gender': validated_data.pop('gender'),
            'height_cm': validated_data.pop('height_cm'),
            'weight_kg': validated_data.pop('weight_kg'),
            'waist_cm': validated_data.pop('waist_cm'),
            'role': validated_data.pop('role'),
            'phone': validated_data.pop('phone', ''),
            'address': validated_data.pop('address', ''),
            'lifestyle': validated_data.pop('lifestyle', ''),
        }

        user = User.objects.create_user(**validated_data)
        PatientProfile.objects.create(user=user, **profile_data)
        return user


class QuestionnaireResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuestionnaireResponse
        fields = '__all__'


class DeviceReadingSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeviceReading
        fields = '__all__'


class AlertSerializer(serializers.ModelSerializer):
    class Meta:
        model = Alert
        fields = '__all__'


class AppointmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Appointment
        fields = '__all__'


class EducationContentSerializer(serializers.ModelSerializer):
    class Meta:
        model = EducationContent
        fields = '__all__'


class SupportGroupSerializer(serializers.ModelSerializer):
    class Meta:
        model = SupportGroup
        fields = '__all__'


class SupportGroupMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = SupportGroupMessage
        fields = '__all__'


class ProviderAssignmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProviderAssignment
        fields = '__all__'


class DeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Device
        fields = '__all__'


class PushDeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = PushDevice
        fields = '__all__'


class DataShareConsentSerializer(serializers.ModelSerializer):
    class Meta:
        model = DataShareConsent
        fields = '__all__'


class QuestionnaireTemplateSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuestionnaireTemplate
        fields = '__all__'


class LabTestSerializer(serializers.ModelSerializer):
    class Meta:
        model = LabTest
        fields = '__all__'


class QuizQuestionSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuizQuestion
        fields = '__all__'


class QuizSerializer(serializers.ModelSerializer):
    questions = QuizQuestionSerializer(many=True, read_only=True)

    class Meta:
        model = Quiz
        fields = ['id', 'title', 'topic', 'created_at', 'questions']


class QuizResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuizResponse
        fields = '__all__'


class DirectMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = DirectMessage
        fields = '__all__'


class AuditLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = AuditLog
        fields = '__all__'


class WorkerAssignmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = WorkerAssignment
        fields = '__all__'
