from rest_framework import viewsets, status
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from core.permissions import IsProvider, IsPatient, IsWorker
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
from .serializers import (
    PatientProfileSerializer,
    HealthRecordSerializer,
    MedicationSerializer,
    QuestionnaireResponseSerializer,
    DeviceReadingSerializer,
    AlertSerializer,
    AppointmentSerializer,
    EducationContentSerializer,
    SupportGroupSerializer,
    SupportGroupMessageSerializer,
    ProviderAssignmentSerializer,
    DeviceSerializer,
    PushDeviceSerializer,
    DataShareConsentSerializer,
    QuestionnaireTemplateSerializer,
    LabTestSerializer,
    QuizSerializer,
    QuizQuestionSerializer,
    QuizResponseSerializer,
    DirectMessageSerializer,
    AuditLogSerializer,
    WorkerAssignmentSerializer,
)
from django.db.models import Avg, Max, Min
from django.db.models.functions import TruncDate
from django.http import HttpResponse
import csv
from datetime import timedelta
from rest_framework.decorators import action
from core.utils.fcm import send_fcm_notification
from rest_framework.views import APIView


class PatientProfileViewSet(viewsets.ModelViewSet):
    queryset = PatientProfile.objects.all()
    serializer_class = PatientProfileSerializer
    permission_classes = [IsAuthenticated]

class HealthRecordViewSet(viewsets.ModelViewSet):
    serializer_class = HealthRecordSerializer
    permission_classes = [IsAuthenticated, IsProvider]

    def get_queryset(self):
        user = self.request.user
        if user.patient_profile.role == 'patient':
            return HealthRecord.objects.filter(patient__user=user)
        if user.patient_profile.role == 'provider':
            assignments = ProviderAssignment.objects.filter(provider=user.patient_profile).values_list('patient_id', flat=True)
            return HealthRecord.objects.filter(patient_id__in=assignments)
        return HealthRecord.objects.none()

    def perform_create(self, serializer):
        instance = serializer.save()
        # Basic alerting logic based on vitals
        systolic = instance.blood_pressure_systolic
        diastolic = instance.blood_pressure_diastolic
        glucose = instance.blood_glucose
        alerts = []
        if systolic is not None and diastolic is not None and (systolic >= 180 or diastolic >= 120):
            alerts.append({
                'alert_type': 'hypertensive_crisis',
                'message': 'Critical blood pressure detected. Seek immediate care.',
                'severity': 'critical'
            })
        if glucose is not None and (glucose < 70):
            alerts.append({
                'alert_type': 'hypoglycemia',
                'message': 'Low blood glucose detected. Take fast-acting carbs.',
                'severity': 'warning'
            })
        if glucose is not None and (glucose >= 300):
            alerts.append({
                'alert_type': 'hyperglycemia',
                'message': 'Very high blood glucose detected. Consider medical advice.',
                'severity': 'warning'
            })
        for alert in alerts:
            Alert.objects.create(patient=instance.patient, **alert)

class MedicationViewSet(viewsets.ModelViewSet):
    queryset = Medication.objects.all()
    serializer_class = MedicationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = self.queryset
        if hasattr(user, 'patient_profile') and user.patient_profile.role == 'patient':
            qs = qs.filter(patient__user=user)
        elif hasattr(user, 'patient_profile') and user.patient_profile.role == 'provider':
            assignments = ProviderAssignment.objects.filter(provider=user.patient_profile).values_list('patient_id', flat=True)
            qs = qs.filter(patient_id__in=assignments)
        elif hasattr(user, 'patient_profile') and user.patient_profile.role == 'worker':
            assigns = WorkerAssignment.objects.filter(worker=user.patient_profile).values_list('patient_id', flat=True)
            qs = qs.filter(patient_id__in=assigns)
        limit = int(self.request.query_params.get('limit', 0) or 0)
        qs = qs.order_by('-id')
        return qs[:limit] if limit > 0 else qs

    def perform_create(self, serializer):
        data = serializer.validated_data
        if 'patient' not in data or data.get('patient') is None:
            if hasattr(self.request.user, 'patient_profile'):
                serializer.save(patient=self.request.user.patient_profile)
                return
        serializer.save()


class QuestionnaireResponseViewSet(viewsets.ModelViewSet):
    queryset = QuestionnaireResponse.objects.all()
    serializer_class = QuestionnaireResponseSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = self.queryset
        if not hasattr(user, 'patient_profile'):
            return qs.none().order_by('-submitted_at', '-id')
        role = user.patient_profile.role
        if role == 'patient':
            qs = qs.filter(patient__user=user)
        elif role == 'provider':
            assignments = ProviderAssignment.objects.filter(provider=user.patient_profile).values_list('patient_id', flat=True)
            qs = qs.filter(patient_id__in=assignments)
        elif role == 'worker':
            assigns = WorkerAssignment.objects.filter(worker=user.patient_profile).values_list('patient_id', flat=True)
            qs = qs.filter(patient_id__in=assigns)
        limit = int(self.request.query_params.get('limit', 0) or 0)
        qs = qs.order_by('-submitted_at', '-id')
        return qs[:limit] if limit > 0 else qs

    def perform_create(self, serializer):
        role = self.request.user.patient_profile.role
        if role not in ['patient', 'worker']:
            raise PermissionDenied('Not allowed to submit responses')
        if 'patient' not in serializer.validated_data or serializer.validated_data.get('patient') is None:
            if hasattr(self.request.user, 'patient_profile'):
                serializer.save(patient=self.request.user.patient_profile)
                return
        serializer.save()

    def list(self, request, *args, **kwargs):
        try:
            queryset = self.get_queryset()
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data)
        except Exception as exc:
            # Fail safe: never block UI; return empty list with reason
            return Response([], status=status.HTTP_200_OK)


class MyQuestionnairesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if not hasattr(user, 'patient_profile'):
            return Response([], status=status.HTTP_200_OK)
        qs = QuestionnaireResponse.objects.filter(patient__user=user).order_by('-submitted_at', '-id')
        data = QuestionnaireResponseSerializer(qs, many=True).data
        return Response(data)


class DeviceReadingViewSet(viewsets.ModelViewSet):
    queryset = DeviceReading.objects.all()
    serializer_class = DeviceReadingSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.patient_profile.role == 'patient':
            return self.queryset.filter(patient__user=user)
        if user.patient_profile.role == 'provider':
            assignments = ProviderAssignment.objects.filter(provider=user.patient_profile).values_list('patient_id', flat=True)
            return self.queryset.filter(patient_id__in=assignments)
        if user.patient_profile.role == 'worker':
            assigns = WorkerAssignment.objects.filter(worker=user.patient_profile).values_list('patient_id', flat=True)
            return self.queryset.filter(patient_id__in=assigns)
        return self.queryset.none()

    def perform_create(self, serializer):
        if not serializer.validated_data.get('patient') and hasattr(self.request.user, 'patient_profile'):
            instance = serializer.save(patient=self.request.user.patient_profile)
        else:
            instance = serializer.save()
        alerts = []
        if instance.reading_type == 'bp' and instance.systolic is not None and instance.diastolic is not None:
            if instance.systolic >= 180 or instance.diastolic >= 120:
                alerts.append({
                    'alert_type': 'hypertensive_crisis',
                    'message': 'Critical blood pressure detected. Seek immediate care.',
                    'severity': 'critical'
                })
        if instance.reading_type == 'glucose':
            if instance.value < 70:
                alerts.append({
                    'alert_type': 'hypoglycemia',
                    'message': 'Low blood glucose detected. Take fast-acting carbs.',
                    'severity': 'warning'
                })
            if instance.value >= 300:
                alerts.append({
                    'alert_type': 'hyperglycemia',
                    'message': 'Very high blood glucose detected. Consider medical advice.',
                    'severity': 'warning'
                })
        for alert in alerts:
            Alert.objects.create(patient=instance.patient, **alert)


class AlertViewSet(viewsets.ModelViewSet):
    queryset = Alert.objects.all()
    serializer_class = AlertSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = self.queryset
        if user.patient_profile.role == 'patient':
            qs = qs.filter(patient__user=user)
        elif user.patient_profile.role == 'provider':
            assignments = ProviderAssignment.objects.filter(provider=user.patient_profile).values_list('patient_id', flat=True)
            qs = qs.filter(patient_id__in=assignments)
        elif user.patient_profile.role == 'worker':
            assigns = WorkerAssignment.objects.filter(worker=user.patient_profile).values_list('patient_id', flat=True)
            qs = qs.filter(patient_id__in=assigns)
        limit = int(self.request.query_params.get('limit', 0) or 0)
        qs = qs.order_by('-created_at', '-id')
        return qs[:limit] if limit > 0 else qs

    @action(detail=True, methods=['post'])
    def acknowledge(self, request, pk=None):
        alert = self.get_object()
        alert.resolved = True
        alert.save(update_fields=['resolved'])
        return Response({'status': 'acknowledged'})

    @action(detail=True, methods=['post'])
    def snooze(self, request, pk=None):
        # For simplicity, mark resolved and create a follow-up info alert
        alert = self.get_object()
        alert.resolved = True
        alert.save(update_fields=['resolved'])
        Alert.objects.create(
            patient=alert.patient,
            alert_type=f"snoozed_{alert.alert_type}",
            message="Reminder snoozed. We'll notify you later.",
            severity='info'
        )
        return Response({'status': 'snoozed'})


class AppointmentViewSet(viewsets.ModelViewSet):
    queryset = Appointment.objects.all()
    serializer_class = AppointmentSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = self.queryset
        if user.patient_profile.role == 'patient':
            qs = qs.filter(patient__user=user)
        elif user.patient_profile.role == 'provider':
            assignments = ProviderAssignment.objects.filter(provider=user.patient_profile).values_list('patient_id', flat=True)
            qs = qs.filter(patient_id__in=assignments)
        elif user.patient_profile.role == 'worker':
            assigns = WorkerAssignment.objects.filter(worker=user.patient_profile).values_list('patient_id', flat=True)
            qs = qs.filter(patient_id__in=assigns)
        limit = int(self.request.query_params.get('limit', 0) or 0)
        qs = qs.order_by('scheduled_for', '-id')
        return qs[:limit] if limit > 0 else qs

    def perform_create(self, serializer):
        data = serializer.validated_data
        if 'patient' not in data or data.get('patient') is None:
            if hasattr(self.request.user, 'patient_profile'):
                serializer.save(patient=self.request.user.patient_profile)
                return
        serializer.save()


class EducationContentViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = EducationContent.objects.all().order_by('-created_at')
    serializer_class = EducationContentSerializer
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'])
    def topics(self, request):
        topics = EducationContent.objects.values_list('topic', flat=True).distinct()
        return Response(sorted(set(topics)))


class SupportGroupViewSet(viewsets.ModelViewSet):
    queryset = SupportGroup.objects.all()
    serializer_class = SupportGroupSerializer
    permission_classes = [IsAuthenticated]


class SupportGroupMessageViewSet(viewsets.ModelViewSet):
    queryset = SupportGroupMessage.objects.all()
    serializer_class = SupportGroupMessageSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        groups = SupportGroup.objects.filter(members__user=user)
        return self.queryset.filter(group__in=groups)

    def perform_create(self, serializer):
        author = getattr(self.request.user, 'patient_profile', None)
        serializer.save(author=author)


class NotificationsViewSet(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    def list(self, request):
        user = request.user
        profile = user.patient_profile
        alerts = Alert.objects.filter(patient=profile, resolved=False).order_by('-created_at')[:50]
        upcoming = Appointment.objects.filter(patient=profile, status='scheduled').order_by('scheduled_for')[:50]
        meds = Medication.objects.filter(patient=profile)
        return Response({
            'alerts': AlertSerializer(alerts, many=True).data,
            'upcoming_appointments': AppointmentSerializer(upcoming, many=True).data,
            'medication_reminders': MedicationSerializer(meds, many=True).data,
        })


class ProviderAssignmentViewSet(viewsets.ModelViewSet):
    queryset = ProviderAssignment.objects.all()
    serializer_class = ProviderAssignmentSerializer
    permission_classes = [IsAuthenticated, IsProvider]

    @action(detail=False, methods=['get'], url_path='my-patients')
    def my_patients(self, request):
        provider_profile = request.user.patient_profile
        assignments = ProviderAssignment.objects.filter(provider=provider_profile)
        patients = [a.patient for a in assignments]
        data = PatientProfileSerializer(patients, many=True).data
        return Response(data)


class WorkerAssignmentViewSet(viewsets.ModelViewSet):
    queryset = WorkerAssignment.objects.all()
    serializer_class = WorkerAssignmentSerializer
    permission_classes = [IsAuthenticated, IsWorker]

    @action(detail=False, methods=['get'], url_path='my-patients')
    def my_patients(self, request):
        worker_profile = request.user.patient_profile
        assigns = WorkerAssignment.objects.filter(worker=worker_profile)
        patients = [a.patient for a in assigns]
        data = PatientProfileSerializer(patients, many=True).data
        return Response(data)


class AnalyticsViewSet(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    def list(self, request):
        user = request.user
        if user.patient_profile.role == 'patient':
            patient = user.patient_profile
        else:
            patient_id = request.query_params.get('patient_id')
            if not patient_id:
                return Response({'error': 'patient_id is required'}, status=status.HTTP_400_BAD_REQUEST)
            try:
                patient = PatientProfile.objects.get(id=patient_id)
            except PatientProfile.DoesNotExist:
                return Response({'error': 'Patient not found'}, status=status.HTTP_404_NOT_FOUND)

        readings = DeviceReading.objects.filter(patient=patient)
        glucose_stats = readings.filter(reading_type='glucose').aggregate(
            min=Min('value'), max=Max('value'), avg=Avg('value')
        )
        systolic_stats = readings.filter(reading_type='bp').aggregate(
            max_sys=Max('systolic'), min_sys=Min('systolic')
        )
        diastolic_stats = readings.filter(reading_type='bp').aggregate(
            max_dia=Max('diastolic'), min_dia=Min('diastolic')
        )

        return Response({
            'glucose': glucose_stats,
            'blood_pressure': {**systolic_stats, **diastolic_stats},
            'count_readings': readings.count(),
        })

    @action(detail=False, methods=['get'], url_path='timeseries')
    def timeseries(self, request):
        user = request.user
        if user.patient_profile.role == 'patient':
            patient = user.patient_profile
        else:
            patient_id = request.query_params.get('patient_id')
            if not patient_id:
                return Response({'error': 'patient_id is required'}, status=status.HTTP_400_BAD_REQUEST)
            try:
                patient = PatientProfile.objects.get(id=patient_id)
            except PatientProfile.DoesNotExist:
                return Response({'error': 'Patient not found'}, status=status.HTTP_404_NOT_FOUND)

        limit = int(request.query_params.get('limit', 100))
        glucose_qs = DeviceReading.objects.filter(patient=patient, reading_type='glucose').order_by('-recorded_at')[:limit]
        bp_qs = DeviceReading.objects.filter(patient=patient, reading_type='bp').order_by('-recorded_at')[:limit]
        glucose = [{'t': r.recorded_at, 'v': r.value} for r in glucose_qs]
        bp = [{'t': r.recorded_at, 'sys': r.systolic, 'dia': r.diastolic} for r in bp_qs]
        return Response({'glucose': list(reversed(glucose)), 'bp': list(reversed(bp))})

    @action(detail=False, methods=['get'], url_path='report')
    def report(self, request):
        """Daily and weekly aggregates for self-monitoring reports."""
        user = request.user
        if user.patient_profile.role == 'patient':
            patient = user.patient_profile
        else:
            patient_id = request.query_params.get('patient_id')
            if not patient_id:
                return Response({'error': 'patient_id is required'}, status=status.HTTP_400_BAD_REQUEST)
            try:
                patient = PatientProfile.objects.get(id=patient_id)
            except PatientProfile.DoesNotExist:
                return Response({'error': 'Patient not found'}, status=status.HTTP_404_NOT_FOUND)

        readings = DeviceReading.objects.filter(patient=patient)
        # Daily aggregates (last 14 days)
        daily_glucose = (
            readings.filter(reading_type='glucose')
            .annotate(day=TruncDate('recorded_at'))
            .values('day')
            .annotate(avg=Avg('value'))
            .order_by('day')
        )
        daily_bp = (
            readings.filter(reading_type='bp')
            .annotate(day=TruncDate('recorded_at'))
            .values('day')
            .annotate(avg_sys=Avg('systolic'), avg_dia=Avg('diastolic'))
            .order_by('day')
        )

        # Simple weekly (last 8 weeks) using 7-day buckets from last 56 days
        # For simplicity, group by date // 7 buckets on client; here we just return daily and counts
        payload = {
            'daily': {
                'glucose': [{'day': d['day'], 'avg': d['avg']} for d in daily_glucose],
                'bp': [{'day': d['day'], 'avg_sys': d['avg_sys'], 'avg_dia': d['avg_dia']} for d in daily_bp],
            },
            'counts': {
                'glucose': readings.filter(reading_type='glucose').count(),
                'bp': readings.filter(reading_type='bp').count(),
                'weight': readings.filter(reading_type='weight').count(),
                'bmi': readings.filter(reading_type='bmi').count(),
                'waist': readings.filter(reading_type='waist').count(),
            }
        }
        return Response(payload)

    @action(detail=False, methods=['get'], url_path='weekly')
    def weekly(self, request):
        user = request.user
        if user.patient_profile.role == 'patient':
            patient = user.patient_profile
        else:
            patient_id = request.query_params.get('patient_id')
            if not patient_id:
                return Response({'error': 'patient_id is required'}, status=status.HTTP_400_BAD_REQUEST)
            try:
                patient = PatientProfile.objects.get(id=patient_id)
            except PatientProfile.DoesNotExist:
                return Response({'error': 'Patient not found'}, status=status.HTTP_404_NOT_FOUND)

        # Build weekly buckets: last 8 weeks based on date // 7 buckets from daily data
        readings = DeviceReading.objects.filter(patient=patient)
        daily_glucose = (
            readings.filter(reading_type='glucose')
            .annotate(day=TruncDate('recorded_at'))
            .values('day')
            .annotate(avg=Avg('value'))
            .order_by('day')
        )
        daily_bp = (
            readings.filter(reading_type='bp')
            .annotate(day=TruncDate('recorded_at'))
            .values('day')
            .annotate(avg_sys=Avg('systolic'), avg_dia=Avg('diastolic'))
            .order_by('day')
        )
        def to_weeks(rows, keys):
            weeks = {}
            for r in rows:
                day = r['day']
                week_start = day - timedelta(days=day.weekday())
                if week_start not in weeks:
                    weeks[week_start] = {k: [] for k in keys}
                for k in keys:
                    weeks[week_start][k].append(r.get(k))
            out = []
            for ws, vals in sorted(weeks.items()):
                item = {'week_start': ws}
                for k, arr in vals.items():
                    arr = [a for a in arr if a is not None]
                    item[k] = sum(arr)/len(arr) if arr else None
                out.append(item)
            return out
        glucose_w = to_weeks(daily_glucose, ['avg'])
        bp_w = to_weeks(daily_bp, ['avg_sys', 'avg_dia'])
        return Response({'glucose': glucose_w, 'bp': bp_w})

    @action(detail=False, methods=['get'], url_path='export')
    def export_csv(self, request):
        user = request.user
        if user.patient_profile.role == 'patient':
            patient = user.patient_profile
        else:
            patient_id = request.query_params.get('patient_id')
            if not patient_id:
                return Response({'error': 'patient_id is required'}, status=status.HTTP_400_BAD_REQUEST)
            try:
                patient = PatientProfile.objects.get(id=patient_id)
            except PatientProfile.DoesNotExist:
                return Response({'error': 'Patient not found'}, status=status.HTTP_404_NOT_FOUND)

        readings = DeviceReading.objects.filter(patient=patient).order_by('-recorded_at')
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="readings.csv"'
        writer = csv.writer(response)
        writer.writerow(['type', 'value', 'unit', 'systolic', 'diastolic', 'recorded_at'])
        for r in readings:
            writer.writerow([r.reading_type, r.value, r.unit, r.systolic, r.diastolic, r.recorded_at.isoformat()])
        return response


class DeviceViewSet(viewsets.ModelViewSet):
    queryset = Device.objects.all()
    serializer_class = DeviceSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return self.queryset.filter(patient__user=user)


class PushDeviceViewSet(viewsets.ModelViewSet):
    queryset = PushDevice.objects.all()
    serializer_class = PushDeviceSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return self.queryset.filter(user=user)

    @action(detail=False, methods=['post'], url_path='send-test')
    def send_test(self, request):
        token = request.data.get('token')
        if not token:
            return Response({'error': 'token is required'}, status=status.HTTP_400_BAD_REQUEST)
        ok, msg = send_fcm_notification(token, 'Test Notification', 'Hello from NCD App!', {'type': 'test'})
        return Response({'success': ok, 'message': msg})


class DataShareConsentViewSet(viewsets.ModelViewSet):
    queryset = DataShareConsent.objects.all()
    serializer_class = DataShareConsentSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        profile = user.patient_profile
        return self.queryset.filter(models.Q(patient=profile) | models.Q(provider=profile))


class QuestionnaireTemplateViewSet(viewsets.ModelViewSet):
    queryset = QuestionnaireTemplate.objects.all()
    serializer_class = QuestionnaireTemplateSerializer
    permission_classes = [IsAuthenticated, IsProvider]

    def get_permissions(self):
        # Allow all authenticated users to read templates; restrict write to providers
        if self.request.method in ('GET', 'HEAD', 'OPTIONS'):
            return [IsAuthenticated()]
        return [IsAuthenticated(), IsProvider()]


class ExportViewSet(viewsets.ViewSet):
    permission_classes = [IsAuthenticated, IsProvider]

    def list(self, request):
        provider = request.user.patient_profile
        patient_id = request.query_params.get('patient_id')
        if not patient_id:
            return Response({'error': 'patient_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            patient = PatientProfile.objects.get(id=patient_id)
        except PatientProfile.DoesNotExist:
            return Response({'error': 'Patient not found'}, status=status.HTTP_404_NOT_FOUND)
        # Check assignment and consent
        assigned = ProviderAssignment.objects.filter(provider=provider, patient=patient).exists()
        consent = DataShareConsent.objects.filter(provider=provider, patient=patient, granted=True).exists()
        if not (assigned and consent):
            return Response({'error': 'Not authorized (assignment and consent required)'}, status=status.HTTP_403_FORBIDDEN)
        # Aggregate export payload
        profile = PatientProfileSerializer(patient).data
        records = HealthRecordSerializer(HealthRecord.objects.filter(patient=patient), many=True).data
        readings = DeviceReadingSerializer(DeviceReading.objects.filter(patient=patient), many=True).data
        meds = MedicationSerializer(Medication.objects.filter(patient=patient), many=True).data
        appts = AppointmentSerializer(Appointment.objects.filter(patient=patient), many=True).data
        return Response({'profile': profile, 'records': records, 'readings': readings, 'medications': meds, 'appointments': appts})


class LabTestViewSet(viewsets.ModelViewSet):
    queryset = LabTest.objects.all()
    serializer_class = LabTestSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.patient_profile.role == 'patient':
            return self.queryset.filter(patient__user=user)
        if user.patient_profile.role == 'provider':
            assignments = ProviderAssignment.objects.filter(provider=user.patient_profile).values_list('patient_id', flat=True)
            return self.queryset.filter(patient_id__in=assignments)
        return self.queryset.none()

    def perform_create(self, serializer):
        if self.request.user.patient_profile.role != 'provider':
            raise PermissionDenied('Only providers can create lab tests')
        serializer.save()


class QuizViewSet(viewsets.ModelViewSet):
    queryset = Quiz.objects.all()
    serializer_class = QuizSerializer
    permission_classes = [IsAuthenticated]


class QuizQuestionViewSet(viewsets.ModelViewSet):
    queryset = QuizQuestion.objects.all()
    serializer_class = QuizQuestionSerializer
    permission_classes = [IsAuthenticated]


class QuizResponseViewSet(viewsets.ModelViewSet):
    queryset = QuizResponse.objects.all()
    serializer_class = QuizResponseSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if not hasattr(user, 'patient_profile'):
            return self.queryset.none().order_by('-submitted_at', '-id')
        return self.queryset.filter(patient=user.patient_profile).order_by('-submitted_at', '-id')

    def perform_create(self, serializer):
        # Attach current patient if not provided
        data = serializer.validated_data
        if 'patient' not in data or data.get('patient') is None:
            if hasattr(self.request.user, 'patient_profile'):
                instance = serializer.save(patient=self.request.user.patient_profile)
            else:
                instance = serializer.save()
        else:
            instance = serializer.save()
        # Compute score
        questions = QuizQuestion.objects.filter(quiz=instance.quiz).order_by('id')
        score = 0
        for idx, q in enumerate(questions):
            try:
                if instance.answers[idx] == q.correct_index:
                    score += 1
            except Exception:
                continue
        instance.score = score
        instance.save(update_fields=['score'])

    def list(self, request, *args, **kwargs):
        try:
            queryset = self.get_queryset()
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data)
        except Exception:
            return Response([], status=status.HTTP_200_OK)

    def create(self, request, *args, **kwargs):
        # Create as usual
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        instance: QuizResponse = serializer.instance
        # Build explanations and suggestions
        questions = QuizQuestion.objects.filter(quiz=instance.quiz).order_by('id')
        explanations = []
        total = questions.count()
        for idx, q in enumerate(questions):
            correct_choice = None
            try:
                correct_choice = (q.choices or [])[q.correct_index]
            except Exception:
                correct_choice = None
            user_choice = None
            try:
                user_choice = (instance.answers or [])[idx]
            except Exception:
                user_choice = None
            explanations.append({
                'question': q.text,
                'correct_index': q.correct_index,
                'correct_choice': correct_choice,
                'your_choice': user_choice,
                'is_correct': (user_choice == q.correct_index),
            })
        # Suggest education items by quiz topic
        suggestions = []
        try:
            items = EducationContent.objects.filter(topic=getattr(instance.quiz, 'topic', 'general')).order_by('-created_at')[:5]
            suggestions = EducationContentSerializer(items, many=True).data
        except Exception:
            suggestions = []
        headers = self.get_success_headers(serializer.data)
        return Response({
            'id': instance.id,
            'score': instance.score,
            'total': total,
            'explanations': explanations,
            'education_suggestions': suggestions,
        }, status=status.HTTP_201_CREATED, headers=headers)


class DirectMessageViewSet(viewsets.ModelViewSet):
    queryset = DirectMessage.objects.all()
    serializer_class = DirectMessageSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user_profile = self.request.user.patient_profile
        return self.queryset.filter(models.Q(sender=user_profile) | models.Q(recipient=user_profile)).order_by('-created_at')


class AuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = AuditLog.objects.all().order_by('-timestamp')
    serializer_class = AuditLogSerializer
    permission_classes = [IsAuthenticated, IsProvider]
