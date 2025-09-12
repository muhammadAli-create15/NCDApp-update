from typing import Literal, Tuple

Sex = Literal['male', 'female']

def compute_bmi(height_cm: float | None, weight_kg: float | None) -> float | None:
	if not height_cm or not weight_kg or height_cm <= 0:
		return None
	h_m = height_cm / 100.0
	return weight_kg / (h_m * h_m)

def ada_type2_risk_score(
	age: int | None,
	sex: Sex | None,
	bmi: float | None,
	family_history: bool | None,
	hypertension: bool | None,
	physically_active: bool | None,
	gestational_dm: bool | None,
) -> Tuple[int, str]:
	"""
	Compute ADA Diabetes Risk Test score (simplified, public questionnaire mapping).
	Returns (score, category).
	Scoring guide (approximate):
	- Age: <40:0, 40-49:1, 50-59:2, >=60:3
	- BMI: <25:0, 25-29.9:1, >=30:2 (for Asian ancestry, thresholds differ; not handled here)
	- Physical activity: No:1, Yes:0
	- Family history (first degree): Yes:1, No:0
	- Ever had hypertension: Yes:1, No:0
	- Sex: Male:1, Female:0
	- Gestational diabetes (females): Yes:1, else:0
	Risk categories: 0-4 low, 5-7 increased, >=8 high
	"""
	score = 0
	if age is not None:
		if age >= 60:
			score += 3
		elif age >= 50:
			score += 2
		elif age >= 40:
			score += 1
	if bmi is not None:
		if bmi >= 30:
			score += 2
		elif bmi >= 25:
			score += 1
	if physically_active is False:
		score += 1
	if family_history:
		score += 1
	if hypertension:
		score += 1
	if sex == 'male':
		score += 1
	if sex == 'female' and gestational_dm:
		score += 1
	if score >= 8:
		cat = 'high'
	elif score >= 5:
		cat = 'increased'
	else:
		cat = 'low'
	return score, cat


