import httpx

from app.config import get_settings


class OTPIQError(RuntimeError):
    pass


async def send_verification_otp(*, phone_number: str, verification_code: str) -> None:
    """
    إرسال OTP عبر OTPIQ (نفس مسار وطلب backend_farah عند التفعيل).
    - phone_number يجب أن يكون مُطبَّعاً وبدون '+'.

    إذا لم يُضبط OTPIQ (مفاتيح فارغة): لا يُرفع خطأ — يُطبع الرمز في الطرفية
    للتطوير المحلي (حتى لا يعيد الـ API 502).
    """
    settings = get_settings()
    if not settings.OTPIQ_API_KEY or not settings.OTPIQ_BASE_URL:
        print(
            f"[OTP DEV] phone={phone_number}  code={verification_code}  "
            f"(ضبط OTPIQ_API_KEY و OTPIQ_BASE_URL في .env لإرسال SMS حقيقي)",
            flush=True,
        )
        return

    base_url = settings.OTPIQ_BASE_URL.rstrip("/")
    url = f"{base_url}/sms"

    headers = {
        "Authorization": f"Bearer {settings.OTPIQ_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "phoneNumber": phone_number,
        "smsType": "verification",
        "verificationCode": verification_code,
        "provider": "sms",
    }

    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.post(url, headers=headers, json=payload)
        if resp.status_code >= 400:
            raise OTPIQError(f"OTPIQ error {resp.status_code}: {resp.text}")
