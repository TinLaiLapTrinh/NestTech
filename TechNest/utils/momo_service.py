# payments/momo_service.py
import time
import uuid
import hmac
import hashlib
import json
import requests
from django.conf import settings

import qrcode
from io import BytesIO
import base64

def generate_qr_from_url(url):
    qr = qrcode.QRCode(box_size=10, border=4)
    qr.add_data(url)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    buffered = BytesIO()
    img.save(buffered, format="PNG")
    img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")
    return f"data:image/png;base64,{img_str}"

def generate_momo_ids(order_id: int):
    """
    Sinh orderId và requestId unique để gửi sang MoMo.
    """
    unique_suffix = str(int(time.time()))  # timestamp (giây)
    momo_order_id = f"{order_id}_{unique_suffix}"
    request_id = str(uuid.uuid4())
    return momo_order_id, request_id


def create_momo_payment(amount: str, order_id: str, order_info: str):
    momo_conf = settings.MOMO_CONFIG
    momo_order_id, request_id = generate_momo_ids(order_id)  # ✅ sinh id chuẩn
    extra_data = ""

    raw_signature = (
        "accessKey=" + momo_conf["accessKey"] +
        "&amount=" + amount +
        "&extraData=" + extra_data +
        "&ipnUrl=" + momo_conf["ipnUrl"] +
        "&orderId=" + momo_order_id +
        "&orderInfo=" + order_info +
        "&partnerCode=" + momo_conf["partnerCode"] +
        "&redirectUrl=" + momo_conf["redirectUrl"] +
        "&requestId=" + request_id +
        "&requestType=payWithMethod"
    )

    signature = hmac.new(
        momo_conf["secretKey"].encode("utf-8"),
        raw_signature.encode("utf-8"),
        hashlib.sha256
    ).hexdigest()

    payload = {
        "partnerCode": momo_conf["partnerCode"],
        "partnerName": "MoMo Payment",
        "storeId": "Test Store",
        "requestId": request_id,
        "amount": str(amount),
        "orderId": momo_order_id,
        "orderInfo": order_info,
        "redirectUrl": momo_conf["redirectUrl"],
        "ipnUrl": momo_conf["ipnUrl"],
        "lang": "vi",
        "extraData": extra_data,
        "requestType": "payWithMethod",
        "signature": signature,
        "autoCapture": True,
        "orderGroupId": ""
    }

    response = requests.post(
        momo_conf["endpoint"],
        data=json.dumps(payload),
        headers={"Content-Type": "application/json"}
    )
    return response.json()
