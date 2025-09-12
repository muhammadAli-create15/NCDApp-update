from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    PatientProfileViewSet,
    HealthRecordViewSet,
    MedicationViewSet,
    QuestionnaireResponseViewSet,
    DeviceReadingViewSet,
    AlertViewSet,
    AppointmentViewSet,
    EducationContentViewSet,
    SupportGroupViewSet,
    SupportGroupMessageViewSet,
    ProviderAssignmentViewSet,
    AnalyticsViewSet,
    NotificationsViewSet,
    DeviceViewSet,
    PushDeviceViewSet,
    DataShareConsentViewSet,
    QuestionnaireTemplateViewSet,
    ExportViewSet,
    LabTestViewSet,
    QuizViewSet,
    QuizQuestionViewSet,
    QuizResponseViewSet,
    DirectMessageViewSet,
    AuditLogViewSet,
    WorkerAssignmentViewSet,
    MyQuestionnairesView,
)
from .views_auth import RegisterView, LogoutView
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from core.views_risk import (
    RiskCalculatorView,
    MLInspiredRiskView,
    RecommendationsView,
    RiskCalculatorMeView,
    MLInspiredRiskMeView,
    AdaDiabetesRiskMeView,
)

router = DefaultRouter()
router.register(r'patients', PatientProfileViewSet)
router.register(r'records', HealthRecordViewSet, basename='healthrecord')  # ✅ Moved here
router.register(r'medications', MedicationViewSet)
router.register(r'questionnaires', QuestionnaireResponseViewSet)
router.register(r'device-readings', DeviceReadingViewSet)
router.register(r'alerts', AlertViewSet)
router.register(r'appointments', AppointmentViewSet)
router.register(r'education', EducationContentViewSet, basename='education')
router.register(r'support-groups', SupportGroupViewSet)
router.register(r'support-group-messages', SupportGroupMessageViewSet)
router.register(r'assignments', ProviderAssignmentViewSet, basename='assignments')
router.register(r'analytics', AnalyticsViewSet, basename='analytics')
router.register(r'notifications', NotificationsViewSet, basename='notifications')
router.register(r'devices', DeviceViewSet)
router.register(r'push-devices', PushDeviceViewSet)
router.register(r'consents', DataShareConsentViewSet, basename='consents')
router.register(r'questionnaire-templates', QuestionnaireTemplateViewSet)
router.register(r'export', ExportViewSet, basename='export')
router.register(r'lab-tests', LabTestViewSet)
router.register(r'quizzes', QuizViewSet)
router.register(r'quiz-questions', QuizQuestionViewSet)
router.register(r'quiz-responses', QuizResponseViewSet)
router.register(r'messages', DirectMessageViewSet, basename='messages')
router.register(r'audit-logs', AuditLogViewSet, basename='audit-logs')
router.register(r'worker-assignments', WorkerAssignmentViewSet, basename='worker-assignments')

urlpatterns = [
    # Put specific paths BEFORE router include to avoid conflicts
    path('questionnaires/my/', MyQuestionnairesView.as_view(), name='my_questionnaires'),
    path('', include(router.urls)),
    path('register/', RegisterView.as_view(), name='register'),
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('logout/', LogoutView.as_view(), name='logout'),
]
from core.views_risk import RiskCalculatorView

urlpatterns += [
    path('risk/<int:patient_id>/', RiskCalculatorView.as_view(), name='risk_calculator'),
    path('risk-ml/<int:patient_id>/', MLInspiredRiskView.as_view(), name='risk_ml'),
    path('risk/me/', RiskCalculatorMeView.as_view(), name='risk_me'),
    path('risk-ml/me/', MLInspiredRiskMeView.as_view(), name='risk_ml_me'),
    path('risk-ada/me/', AdaDiabetesRiskMeView.as_view(), name='risk_ada_me'),
    path('recommendations/', RecommendationsView.as_view(), name='recommendations'),
]
