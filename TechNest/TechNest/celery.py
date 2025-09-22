import os
from celery import Celery

# Set default settings module cho Django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "TechNest.settings")

# Tạo Celery app
app = Celery("TechNest")

# Load config từ Django settings, prefix CELERY_
app.config_from_object("django.conf:settings", namespace="CELERY")

# Tự động tìm tasks trong các app Django
app.autodiscover_tasks()
