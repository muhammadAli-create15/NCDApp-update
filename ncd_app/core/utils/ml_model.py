import os
from typing import Any, Dict, Optional

_MODEL = None
_MODEL_INFO: Dict[str, Any] = {
	"loaded": False,
	"path": None,
	"framework": None,
	"version": None,
}

def _try_imports():
	try:
		import joblib  # type: ignore
		return joblib
	except Exception:
		return None

def load_model_if_available() -> None:
	global _MODEL, _MODEL_INFO
	if _MODEL is not None or _MODEL_INFO["loaded"]:
		return
	path = os.environ.get("NCD_RISK_MODEL_PATH")
	if not path:
		return
	joblib = _try_imports()
	if not joblib:
		return
	try:
		model = joblib.load(path)
		_MODEL = model
		_MODEL_INFO.update({
			"loaded": True,
			"path": path,
			"framework": "scikit-learn/joblib",
			"version": getattr(model, "__class__", type(model)).__name__,
		})
	except Exception:
		_MODEL = None
		_MODEL_INFO = {"loaded": False, "path": path, "framework": None, "version": None}

def model_info() -> Dict[str, Any]:
	load_model_if_available()
	return dict(_MODEL_INFO)

def predict_risk(features: Dict[str, float]) -> Optional[float]:
	"""Return probability (0.0-1.0) if a compatible model is loaded, else None."""
	load_model_if_available()
	if _MODEL is None:
		return None
	try:
		# Expect model to implement predict_proba([[...]]). Use alphabetical order of keys for stability.
		ordered_keys = sorted(features.keys())
		X = [[features[k] for k in ordered_keys]]
		if hasattr(_MODEL, "predict_proba"):
			proba = _MODEL.predict_proba(X)
			# Assume positive class is index 1
			return float(proba[0][1])
		elif hasattr(_MODEL, "predict"):
			y = _MODEL.predict(X)
			# Map decision function or score to [0,1] if possible
			val = float(y[0])
			# naive squashing
			return 1.0/(1.0 + pow(2.718281828, -val))
	except Exception:
		return None


