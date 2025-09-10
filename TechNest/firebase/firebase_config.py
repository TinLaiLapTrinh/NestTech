import firebase_admin
from firebase_admin import credentials, messaging

from accounts.models import FcmToken

cred = credentials.Certificate("./firebase/notification-600a5-firebase-adminsdk-fbsvc-2f5f26028e.json")
firebase_admin.initialize_app(cred)

def send_push_notification(token, title, body):
    """Gửi 1 thông báo push đến 1 device"""
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        token=token,
    )
    response = messaging.send(message)
    return response

def send_push_notification_multiple(tokens, title, body):
    """Gửi 1 thông báo push đến nhiều device"""
    message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        tokens=tokens,
    )
    response = messaging.send_multicast(message)
    return response



def send_order_notification(user, title, body, exclude_token=None):
    tokens = list(user.fcm_tokens.values_list("token", flat=True))
    if exclude_token:
        tokens = [t for t in tokens if t != exclude_token]

    if not tokens:
        return

    message = messaging.MulticastMessage(
        notification=messaging.Notification(title=title, body=body),
        tokens=tokens,
    )
    response = messaging.send_each_for_multicast(message)

    for i, resp in enumerate(response.responses):
        if i >= len(tokens): 
            continue
        if not resp.success:
            FcmToken.objects.filter(token=tokens[i]).delete()

