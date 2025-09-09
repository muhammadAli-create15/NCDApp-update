try:
    from .celery import app as celery_app
    __all__ = ('celery_app',)
except Exception:
    # Allow Django to start even if Celery isn't installed/running
    __all__ = ()

