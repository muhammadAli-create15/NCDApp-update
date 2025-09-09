# core/permissions.py

from rest_framework.permissions import BasePermission

class IsProvider(BasePermission):
    """
    Custom permission to allow only users with role 'provider' to access certain views.
    Assumes user has a related PatientProfile with a 'role' field.
    """

    def has_permission(self, request, view):
        user = request.user
        return (
            user.is_authenticated and
            hasattr(user, 'patient_profile') and
            user.patient_profile.role == 'provider'
        )


class IsPatient(BasePermission):
    def has_permission(self, request, view):
        user = request.user
        return (
            user.is_authenticated and
            hasattr(user, 'patient_profile') and
            user.patient_profile.role == 'patient'
        )


class IsWorker(BasePermission):
    def has_permission(self, request, view):
        user = request.user
        return (
            user.is_authenticated and
            hasattr(user, 'patient_profile') and
            user.patient_profile.role == 'worker'
        )
