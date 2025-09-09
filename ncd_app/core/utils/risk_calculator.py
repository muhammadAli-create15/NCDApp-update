# core/utils/risk_calculator.py

def calculate_bmi(weight_kg, height_cm):
    height_m = height_cm / 100.0
    return round(weight_kg / (height_m ** 2), 2)

def calculate_diabetes_risk(profile, record):
    score = 0

    if profile.age >= 45:
        score += 1
    bmi = calculate_bmi(profile.weight_kg, profile.height_cm)
    if bmi >= 25:
        score += 1
    if profile.gender.lower() == 'male' and profile.waist_cm >= 94:
        score += 1
    if profile.gender.lower() == 'female' and profile.waist_cm >= 80:
        score += 1
    if record.blood_glucose >= 126:
        score += 2
    if record.blood_pressure_systolic >= 140 or record.blood_pressure_diastolic >= 90:
        score += 1

    return score

def calculate_hypertension_risk(profile, record):
    score = 0

    if profile.age >= 40:
        score += 1
    bmi = calculate_bmi(profile.weight_kg, profile.height_cm)
    if bmi >= 25:
        score += 1
    if record.blood_pressure_systolic >= 140 or record.blood_pressure_diastolic >= 90:
        score += 2

    return score
