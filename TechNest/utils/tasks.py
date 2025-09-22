from celery import shared_task
from django.conf import settings
from products.models import Rate
import requests

def check_spam_akismet(comment_text, user_ip, user_agent="python-client"):
    print(f"{comment_text, user_ip}")
    url = "https://rest.akismet.com/1.1/comment-check"
    data = {
        "blog": settings.BLOG_URL,
        "user_ip": user_ip,
        "user_agent": user_agent,
        "comment_content": comment_text,
        "comment_type": "review"
    }
    headers = {"Authorization": f"Bearer {settings.AKISMET_API_KEY}"}
    response = requests.post(url, data=data, headers=headers)
    if response.status_code == 200:
        return response.text == "true" 
    else:
        raise Exception(f"Akismet API error: {response.status_code} - {response.text}")

@shared_task
def check_spam_rate(rate_id):
    try:
        rate = Rate.objects.get(id=rate_id)
        is_spam_flag = check_spam_akismet(rate.content, rate.ip_address)
        rate.is_spam = is_spam_flag
        rate.save(update_fields=["is_spam"])
        return {"rate_id": rate.id, "is_spam": is_spam_flag}
    except Rate.DoesNotExist:
        return {"error": "Rate not found"}
