import json
import requests
from django.conf import settings


def send_fcm_notification(token: str, title: str, body: str, data: dict | None = None) -> tuple[bool, str]:
    server_key = getattr(settings, 'FCM_SERVER_KEY', None)
    if not server_key:
        return False, 'FCM_SERVER_KEY not configured'
    payload = {
        'to': token,
        'notification': {
            'title': title,
            'body': body,
        },
        'data': data or {},
    }
    headers = {
        'Authorization': f'key={server_key}',
        'Content-Type': 'application/json'
    }
    resp = requests.post('https://fcm.googleapis.com/fcm/send', data=json.dumps(payload), headers=headers, timeout=10)
    if resp.status_code == 200:
        return True, 'ok'
    return False, f'{resp.status_code}: {resp.text}'


