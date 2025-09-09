from django.db.models.signals import post_save
from django.dispatch import receiver
from core.models import Alert, PushDevice, AuditLog, HealthRecord, Medication, Appointment, DeviceReading
from core.utils.fcm import send_fcm_notification


@receiver(post_save, sender=Alert)
def push_on_alert(sender, instance: Alert, created: bool, **kwargs):
    if not created:
        return
    user = instance.patient.user
    tokens = PushDevice.objects.filter(user=user).values_list('token', flat=True)
    for token in tokens:
        send_fcm_notification(token, f"{instance.alert_type}", instance.message, {'severity': instance.severity})


def _audit(instance, action: str, user=None):
    try:
        AuditLog.objects.create(
            user=user,
            model=instance.__class__.__name__,
            object_id=str(getattr(instance, 'id', '')),
            action=action,
        )
    except Exception:
        pass


@receiver(post_save, sender=HealthRecord)
def audit_healthrecord(sender, instance, created, **kwargs):
    _audit(instance, 'create' if created else 'update')


@receiver(post_save, sender=Medication)
def audit_medication(sender, instance, created, **kwargs):
    _audit(instance, 'create' if created else 'update')


@receiver(post_save, sender=Appointment)
def audit_appointment(sender, instance, created, **kwargs):
    _audit(instance, 'create' if created else 'update')


@receiver(post_save, sender=DeviceReading)
def audit_devicereading(sender, instance, created, **kwargs):
    _audit(instance, 'create' if created else 'update')


