# core/admin.py

from django.contrib import admin
from .models import (
    PatientProfile, HealthRecord, Medication,
    QuestionnaireResponse, DeviceReading, Alert, Appointment,
    EducationContent, SupportGroup, SupportGroupMessage, ProviderAssignment,
    Device, PushDevice, DataShareConsent, QuestionnaireTemplate,
    LabTest, Quiz, QuizQuestion, QuizResponse, DirectMessage, AuditLog,
    WorkerAssignment,
)

admin.site.register(PatientProfile)
admin.site.register(HealthRecord)
admin.site.register(Medication)
admin.site.register(QuestionnaireResponse)
admin.site.register(DeviceReading)
admin.site.register(Alert)
admin.site.register(Appointment)
admin.site.register(EducationContent)
admin.site.register(SupportGroup)
admin.site.register(SupportGroupMessage)
admin.site.register(ProviderAssignment)
admin.site.register(Device)
admin.site.register(PushDevice)
admin.site.register(DataShareConsent)
admin.site.register(QuestionnaireTemplate)
admin.site.register(LabTest)
admin.site.register(Quiz)
admin.site.register(QuizQuestion)
admin.site.register(QuizResponse)
admin.site.register(DirectMessage)
admin.site.register(AuditLog)
admin.site.register(WorkerAssignment)
