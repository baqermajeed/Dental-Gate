from fastapi import HTTPException
from beanie import PydanticObjectId as OID

from app.constants import Role
from app.models import User
from app.models.doctor_profile import DoctorProfile
from app.security import create_access_token, create_refresh_token, decode_token
from app.services import experience_score_service as experience_score_svc
from app.services.otp_service import (
    create_otp_request,
    normalize_iraqi_phone,
    verify_otp_or_raise,
)
from app.services.otpiq import OTPIQError, send_verification_otp


async def request_otp(phone: str) -> None:
    """إنشاء وإرسال رمز OTP للهاتف (نفس تدفق backend_farah)."""
    code, otp = await create_otp_request(phone=phone)
    try:
        await send_verification_otp(phone_number=otp.phone, verification_code=code)
    except OTPIQError as e:
        raise HTTPException(status_code=502, detail="Failed to send OTP") from e


async def verify_otp_and_login(
    *,
    phone: str,
    code: str,
) -> tuple[tuple[str, str] | None, User | None]:
    """التحقق من OTP؛ إن وُجد حساب يُرجع التوكنات، وإلا account_exists: false في الراوتر."""
    await verify_otp_or_raise(phone=phone, code=code)

    normalized = normalize_iraqi_phone(phone)
    variants = {phone.strip(), normalized}
    if normalized.startswith("9647") and len(normalized) > 3:
        variants.add("0" + normalized[3:])

    user = await User.find_one({"phone": {"$in": list(variants)}})

    if not user:
        return None, None

    if user.role != Role.DENTIST:
        raise HTTPException(
            status_code=400,
            detail="OTP login is allowed for dentists only",
        )

    token_data = {
        "sub": str(user.id),
        "role": user.role.value,
        "phone": user.phone,
        "email": user.email,
    }
    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)
    return (access_token, refresh_token), user


async def create_dentist_account(
    *,
    name: str,
    phone: str,
    email: str,
    age: int,
    gender: str,
) -> User:
    """إنشاء حساب طبيب بعد التحقق من OTP (يُفترض أن العميل نفّذ verify-otp أولاً)."""
    normalized = normalize_iraqi_phone(phone)
    variants = {phone.strip(), normalized}
    if normalized.startswith("9647") and len(normalized) > 3:
        variants.add("0" + normalized[3:])

    if await User.find_one({"phone": {"$in": list(variants)}}):
        raise HTTPException(status_code=400, detail="Phone already exists")

    if await User.find_one(User.email == email.strip().lower()):
        raise HTTPException(status_code=400, detail="Email already exists")

    user = User(
        name=name.strip(),
        phone=normalized,
        email=email.strip().lower(),
        role=Role.DENTIST,
        gender=gender,
        age=age,
    )
    await user.insert()
    # أنشئ بروفايل افتراضي واحسب السكور الأولي لضمان تخزينه لكل طبيب.
    profile = DoctorProfile(user_id=user.id)
    await profile.insert()
    await experience_score_svc.recompute_and_persist_for_user(user.id)
    return user


async def refresh_access_token(refresh_token: str) -> tuple[str, str]:
    try:
        payload = decode_token(refresh_token, token_type="refresh")
        user_id: str | None = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="Invalid refresh token")

        user = await User.get(OID(user_id))
        if not user:
            raise HTTPException(status_code=401, detail="User not found")

        token_data = {
            "sub": str(user.id),
            "role": user.role.value,
            "phone": user.phone,
            "email": user.email,
        }
        new_access_token = create_access_token(token_data)
        new_refresh_token = create_refresh_token(token_data)
        return new_access_token, new_refresh_token
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")
