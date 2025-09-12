# core/views_risk.py

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from core.models import PatientProfile, HealthRecord
from core.utils.risk_calculator import calculate_diabetes_risk, calculate_hypertension_risk
from core.utils.ml_model import predict_risk, model_info
from core.utils.ada_risk import ada_type2_risk_score, compute_bmi
from django.shortcuts import get_object_or_404

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
        record = HealthRecord.objects.filter(patient=profile).order_by('-timestamp').first()

        if not record:
            return Response({"error": "No health record found for this patient"}, status=404)

        # Simple heuristic combining normalized vitals into a 0-100 score
        bp_score = 0
        if record.blood_pressure_systolic and record.blood_pressure_diastolic:
            sys = record.blood_pressure_systolic
            dia = record.blood_pressure_diastolic
            bp_score = max(0, min(100, (sys - 110) * 0.8 + (dia - 70) * 1.0))

        glucose_score = 0
        if record.blood_glucose is not None:
            glucose = record.blood_glucose
            glucose_score = max(0, min(100, (glucose - 90) * 0.5))

        bmi = None
        if profile.height_cm and profile.weight_kg and profile.height_cm > 0:
            h_m = profile.height_cm / 100.0
            bmi = profile.weight_kg / (h_m * h_m)
        bmi_score = 0 if bmi is None else max(0, min(100, (bmi - 22) * 3.0))

        # Prefer real model if available, otherwise fallback to heuristic
        prob = predict_risk({
            'sys': float(sys) if 'sys' in locals() else 0.0,
            'dia': float(dia) if 'dia' in locals() else 0.0,
            'glucose': float(glucose) if 'glucose' in locals() else 0.0,
            'bmi': float(bmi) if bmi is not None else 0.0,
        })
        combined = (prob * 100.0) if prob is not None else max(0, min(100, 0.4 * bp_score + 0.4 * glucose_score + 0.2 * bmi_score))

        return Response({
            "patient": profile.user.username,
            "ml_risk_score": round(combined, 1),
            "components": {
                "bp_score": round(bp_score, 1),
                "glucose_score": round(glucose_score, 1),
                "bmi_score": round(bmi_score, 1),
            },
            "model": model_info(),
        })


class RiskCalculatorMeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile = PatientProfile.objects.filter(user=request.user).first()
        if not profile:
            return Response({"error": "No patient profile for current user"}, status=400)
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


class MLInspiredRiskMeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile = PatientProfile.objects.filter(user=request.user).first()
        if not profile:
            return Response({"error": "No patient profile for current user"}, status=400)
        record = HealthRecord.objects.filter(patient=profile).order_by('-timestamp').first()
        if not record:
            return Response({"error": "No health record found for this patient"}, status=404)
        bp_score = 0
        if record.blood_pressure_systolic and record.blood_pressure_diastolic:
            sys = record.blood_pressure_systolic
            dia = record.blood_pressure_diastolic
            bp_score = max(0, min(100, (sys - 110) * 0.8 + (dia - 70) * 1.0))
        glucose_score = 0
        if record.blood_glucose is not None:
            glucose = record.blood_glucose
            glucose_score = max(0, min(100, (glucose - 90) * 0.5))
        bmi = None
        if getattr(profile, 'height_cm', None) and getattr(profile, 'weight_kg', None) and profile.height_cm > 0:
            h_m = profile.height_cm / 100.0
            bmi = profile.weight_kg / (h_m * h_m)
        bmi_score = 0 if bmi is None else max(0, min(100, (bmi - 22) * 3.0))
        combined = max(0, min(100, 0.4 * bp_score + 0.4 * glucose_score + 0.2 * bmi_score))
        return Response({
            "patient": profile.user.username,
            "ml_risk_score": round(combined, 1),
            "components": {
                "bp_score": round(bp_score, 1),
                "glucose_score": round(glucose_score, 1),
                "bmi_score": round(bmi_score, 1),
            },
        })

class RecommendationsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # Be defensive to avoid 500s if profile or records are missing
        profile = PatientProfile.objects.filter(user=request.user).first()
        if not profile:
            return Response({"error": "No patient profile for current user"}, status=400)
        record = HealthRecord.objects.filter(patient=profile).order_by('-timestamp').first()

        tips = []

        # BMI-based recommendations
        if getattr(profile, 'height_cm', None) and getattr(profile, 'weight_kg', None) and profile.height_cm > 0:
            h_m = profile.height_cm / 100.0
            bmi = profile.weight_kg / (h_m * h_m)
            if bmi < 18.5:
                tips.append("Increase calorie intake with nutrient-dense foods; consult a dietician.")
            elif bmi < 25:
                tips.append("Maintain balanced diet and regular physical activity (150 min/week).")
            else:
                tips.append("Aim for 5-10% weight loss via calorie deficit and daily activity.")

        # Blood pressure-based recommendations
        if record and getattr(record, 'blood_pressure_systolic', None) and getattr(record, 'blood_pressure_diastolic', None):
            sys = record.blood_pressure_systolic
            dia = record.blood_pressure_diastolic
            if sys >= 140 or dia >= 90:
                tips.append("Reduce salt to <5g/day; DASH-style diet; monitor BP twice daily.")
            if sys >= 180 or dia >= 120:
                tips.append("Hypertensive crisis warning: seek immediate medical care.")

        # Glucose-based recommendations
        if record and getattr(record, 'blood_glucose', None) is not None:
            g = record.blood_glucose
            if g >= 180:
                tips.append("Limit refined sugars; prefer low-glycemic foods; walk 15–30 min after meals.")
            if g < 70:
                tips.append("Carry fast-acting carbohydrates; review medication timing and meals.")

        # Lifestyle defaults
        if not tips:
            tips.append("Stay hydrated, 7–8 hours sleep, and 30 minutes brisk walking daily.")

        return Response({
            "patient": profile.user.username,
            "recommendations": tips,
        })


class AdaDiabetesRiskMeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile = PatientProfile.objects.filter(user=request.user).first()
        if not profile:
            return Response({"error": "No patient profile for current user"}, status=400)
        # Map questionnaire/record signals to ADA inputs
        record = HealthRecord.objects.filter(patient=profile).order_by('-timestamp').first()
        bmi = compute_bmi(profile.height_cm, profile.weight_kg)
        # Infer hypertension if last BP >=140/90
        hypertension = False
        if record and record.blood_pressure_systolic and record.blood_pressure_diastolic:
            hypertension = (record.blood_pressure_systolic >= 140 or record.blood_pressure_diastolic >= 90)
        # Lacking detailed questionnaire fields here; default to conservative False
        family_history = False
        physically_active = True
        gestational_dm = False
        score, category = ada_type2_risk_score(profile.age, 'male' if str(profile.gender).lower().startswith('m') else 'female', bmi, family_history, hypertension, physically_active, gestational_dm)
        return Response({
            'patient': profile.user.username,
            'ada_score': score,
            'category': category,
            'bmi': round(bmi, 1) if bmi is not None else None,
            'hypertension_flag': hypertension,
        })
