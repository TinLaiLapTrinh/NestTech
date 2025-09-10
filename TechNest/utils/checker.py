# utils/spam_checker.py
import os
import requests

AKISMET_API_KEY = os.getenv("AKISMET_API_KEY")
BLOG_URL = os.getenv("BLOG_URL", "http://localhost:8000")

AKISMET_BASE = f"https://{AKISMET_API_KEY}.rest.akismet.com/1.1"

def verify_key():
    """Verify the Akismet API key"""
    data = {
        "key": AKISMET_API_KEY,
        "blog": BLOG_URL
    }
    resp = requests.post(f"{AKISMET_BASE}/verify-key", data=data)
    return resp.text == "valid"

def check_spam(comment_content, user_ip, user_agent, comment_author=""):
    """Check if a comment is spam"""
    data = {
        "blog": BLOG_URL,
        "user_ip": user_ip,
        "user_agent": user_agent,
        "comment_content": comment_content,
        "comment_author": comment_author
    }
    resp = requests.post(f"{AKISMET_BASE}/comment-check", data=data)
    return resp.text.lower() == "true"

def submit_spam(comment_content, user_ip, user_agent, comment_author=""):
    """Report a comment as spam to Akismet"""
    data = {
        "blog": BLOG_URL,
        "user_ip": user_ip,
        "user_agent": user_agent,
        "comment_content": comment_content,
        "comment_author": comment_author
    }
    requests.post(f"{AKISMET_BASE}/submit-spam", data=data)

def submit_ham(comment_content, user_ip, user_agent, comment_author=""):
    """Report a comment as false positive (ham)"""
    data = {
        "blog": BLOG_URL,
        "user_ip": user_ip,
        "user_agent": user_agent,
        "comment_content": comment_content,
        "comment_author": comment_author
    }
    requests.post(f"{AKISMET_BASE}/submit-ham", data=data)
