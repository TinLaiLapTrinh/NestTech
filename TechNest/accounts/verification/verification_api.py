import requests
import hashlib
import json
from TechNest import settings
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad
import base64
import hmac



def hash_cccd(cccd_data: dict) -> str:
    """
    Hash thông tin CCCD với HMAC + SHA256
    """
    
    payload = json.dumps(cccd_data, sort_keys=True, ensure_ascii=False)
    
    payload_bytes = payload.encode("utf-8")
    
    digest = hmac.new(settings.CCCD_SECRET_KEY, payload_bytes, hashlib.sha256).hexdigest()
    return digest

def encrypt_cccd(cccd_data: dict) -> str:
    from Crypto.Cipher import AES
    from Crypto.Util.Padding import pad
    import base64
    from django.conf import settings
    import json

    key = settings.CCCD_SECRET_KEY  
    data_bytes = json.dumps(cccd_data, ensure_ascii=False).encode("utf-8")
    cipher = AES.new(key, AES.MODE_CBC)
    ct_bytes = cipher.encrypt(pad(data_bytes, AES.block_size))
    
    return base64.b64encode(cipher.iv + ct_bytes).decode('utf-8')

def decrypt_cccd(enc_cccd: str) -> dict:
    """
    Giải mã CCCD đã mã hóa bằng AES-CBC
    enc_cccd: base64 string lưu trong DB (IV + ciphertext)
    Trả về dict ban đầu
    """
    key = settings.CCCD_SECRET_KEY  
    raw = base64.b64decode(enc_cccd)
    
    iv = raw[:16]               
    ct = raw[16:]
    
    cipher = AES.new(key, AES.MODE_CBC, iv)
    data_bytes = unpad(cipher.decrypt(ct), AES.block_size)
    
    return json.loads(data_bytes.decode('utf-8'))

def recognize_id_card(image_file):
    """
    image_file: InMemoryUploadedFile từ request.FILES
    """
    headers = {"api-key": settings.FPT_API_KEY}


    files = {
        "image": (image_file.name, image_file, image_file.content_type)
    }

    response = requests.post(settings.API_URL, headers=headers, files=files, timeout=15)
    print(response.json())
    response.raise_for_status()
    return response.json()

