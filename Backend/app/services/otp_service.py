import hashlib
import hmac
import re
import secrets
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException

from app.config import get_settings
from app.models.otp import OTPRequest

_MAX_ATTEMPTS = 5


def normalize_iraqi_phone(phone: str) -> str:
    """
    Normalize Iraqi phone numbers (مطابق لـ backend_farah):
    - remove spaces and dashes
    - if starts with '+', remove '+'
    - if starts with '07', convert to '9647...'
    """
    raw = (phone or "").strip()
    raw = re.sub(r"[\s\-]+", "", raw)
    if raw.startswith("+"):
        raw = raw[1:]
    if raw.startswith("07"):
        raw = "964" + raw[1:]
    return raw


def iraqi_phone_for_display(phone: str | None) -> str:
    """
    عرض الرقم كما يُكتب محلياً (يبدأ بـ 07) رغم أن التخزين قد يكون بصيغة 964...
    لا يُستخدم للتحقق أو الفهرس — فقط للاستجابات المعروضة للمستخدم.
    """
    if not phone or not str(phone).strip():
        return ""
    raw = re.sub(r"[\s\-]+", "", str(phone).strip())
    if raw.startswith("+"):
        raw = raw[1:]
    if raw.startswith("9647") and len(raw) >= 12:
        return "0" + raw[3:]
    if raw.startswith("07"):
        return raw
    if raw.startswith("7") and len(raw) == 10:
        return "0" + raw
    return str(phone).strip()


def generate_otp_code() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


def _otp_secret_bytes() -> bytes:
    """مفتاح HMAC من إعدادات التطبيق (لا يُخزَّن في قاعدة البيانات)."""
    settings = get_settings()
    return ("otp_hmac_v1:" + settings.JWT_SECRET).encode("utf-8")


def hash_otp(code: str) -> str:
    """تجزئة OTP بـ HMAC-SHA256 (بدون passlib/bcrypt — يتوافق مع bcrypt 4.x)."""
    digest = hmac.new(
        _otp_secret_bytes(),
        code.strip().encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()
    return f"hmac-sha256:{digest}"


def verify_hashed_otp(code: str, code_hash: str) -> bool:
    if not code_hash.startswith("hmac-sha256:"):
        return False
    return hmac.compare_digest(hash_otp(code), code_hash)


async def create_otp_request(*, phone: str) -> tuple[str, OTPRequest]:
    settings = get_settings()
    ttl_seconds = settings.OTP_TTL_SECONDS or 120

    normalized = normalize_iraqi_phone(phone)
    if not normalized:
        raise HTTPException(status_code=400, detail="Invalid phone")

    code = generate_otp_code()
    now = datetime.now(timezone.utc)
    expires = now + timedelta(seconds=ttl_seconds)

    otp = OTPRequest(
        phone=normalized,
        code_hash=hash_otp(code),
        expires_at=expires,
        attempts=0,
        verified_at=None,
    )
    await otp.insert()
    return code, otp


async def verify_otp_or_raise(*, phone: str, code: str) -> OTPRequest:
    normalized = normalize_iraqi_phone(phone)
    if not normalized:
        raise HTTPException(status_code=400, detail="Invalid phone")

    now = datetime.now(timezone.utc)
    otp = (
        await OTPRequest.find(
            OTPRequest.phone == normalized,
            OTPRequest.verified_at == None,  # noqa: E711
        )
        .sort(-OTPRequest.created_at)
        .first_or_none()
    )
    if not otp:
        raise HTTPException(status_code=400, detail="OTP not found")

    expires_at = otp.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)

    if otp.attempts >= _MAX_ATTEMPTS:
        raise HTTPException(status_code=400, detail="Too many attempts")

    if expires_at < now:
        raise HTTPException(status_code=400, detail="Invalid or expired code")

    if not verify_hashed_otp(code.strip(), otp.code_hash):
        otp.attempts = int(otp.attempts or 0) + 1
        await otp.save()
        raise HTTPException(status_code=400, detail="Invalid or expired code")

    otp.verified_at = now
    await otp.save()
    return otp
