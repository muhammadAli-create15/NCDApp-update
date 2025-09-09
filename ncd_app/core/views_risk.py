# core/views_risk.py

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from core.models import PatientProfile, HealthRecord, DeviceReading
from core.utils.risk_calculator import calculate_diabetes_risk, calculate_hypertension_risk
from django.shortcuts import get_object_or_404
from django.db.models import Avg

class RiskCalculatorView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, patient_id):
        profile = get_object_or_404(PatientProfile, id=patient_id)
        record = HealthRecord.objects.filter(patient=profile).order_by('-timestamp').first()

        if not record:
            return Response({"error": "No health record found for this patient"}, status=404)

        diabetes_score = calculate_diabetes_risk(profile, record)
        hypertension_score = calculate_hypertension_risk(profile, record)

        return Response({
            "patient": profile.user.username,
            "diabetes_risk_score": diabetes_score,
            "hypertension_risk_score": hypertension_score
        })


class MLInspiredRiskView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, patient_id):
        profile = get_object_or_404(PatientProfile, id=patient_id)
        # Use latest/average signals as simple features
        latest_bp = DeviceReading.objects.filter(patient=profile, reading_type='bp').order_by('-recorded_at').first()
        glucose_stats = DeviceReading.objects.filter(patient=profile, reading_type='glucose').aggregate(avg_glucose=Avg('value'))
        bmi = (profile.weight_kg / ((profile.height_cm / 100.0) ** 2)) if profile.height_cm else 0
        features = {
            'age': profile.age,
            'bmi': round(bmi, 2),
            'avg_glucose': round(glucose_stats.get('avg_glucose') or 0, 2),
            'systolic': latest_bp.systolic if latest_bp else None,
            'diastolic': latest_bp.diastolic if latest_bp else None,
        }
        # Heuristic scoring to mimic a simple model (deterministic, no deps)
        score = 0.0
        score += 0.02 * features['age']
        score += 0.8 if features['bmi'] >= 30 else (0.4 if features['bmi'] >= 25 else 0)
        score += 0.6 if features['avg_glucose'] >= 180 else (0.3 if features['avg_glucose'] >= 140 else 0)
        if features['systolic'] and features['diastolic']:
            score += 0.7 if (features['systolic'] >= 160 or features['diastolic'] >= 100) else (0.4 if (features['systolic'] >= 140 or features['diastolic'] >= 90) else 0)
        risk_percent = max(0, min(100, int(score * 20)))
        return Response({'patient': profile.user.username, 'risk_percent': risk_percent, 'features': features})
