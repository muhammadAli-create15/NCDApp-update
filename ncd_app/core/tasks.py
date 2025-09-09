from datetime import datetime, timedelta
from celery import shared_task
from django.utils import timezone
from core.models import Medication, Appointment, Alert
from core.models import PushDevice
from core.utils.fcm import send_fcm_notification


@shared_task
def check_upcoming_appointments():
    now = timezone.now()
    soon = now + timedelta(days=1)
    qs = Appointment.objects.filter(status='scheduled', scheduled_for__range=(now, soon))
    for appt in qs:
        alert = Alert.objects.create(
            patient=appt.patient,
            alert_type='appointment_reminder',
            message=f"Upcoming appointment: {appt.title} at {appt.scheduled_for}",
            severity='info',
        )
        tokens = PushDevice.objects.filter(user=appt.patient.user).values_list('token', flat=True)
        for token in tokens:
            send_fcm_notification(token, 'Appointment Reminder', alert.message, {'type': 'appointment'})


@shared_task
def daily_medication_reminders():
    now = timezone.localtime()
    meds = Medication.objects.filter(reminder_time__hour=now.hour, reminder_time__minute=now.minute)
    for med in meds:
        alert = Alert.objects.create(
            patient=med.patient,
            alert_type='medication_reminder',
            message=f"Time to take {med.name} ({med.dosage})",
            severity='info',
        )
        tokens = PushDevice.objects.filter(user=med.patient.user).values_list('token', flat=True)
        for token in tokens:
            send_fcm_notification(token, 'Medication Reminder', alert.message, {'type': 'medication'})


