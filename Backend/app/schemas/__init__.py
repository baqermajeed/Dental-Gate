from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.constants import Role

# بروفايل الطبيب (مخططات إضافية في doctor_profile.py)
from app.schemas.doctor_profile import (  # noqa: F401
    DoctorProfileFullOut,
    DoctorProfilePatch,
    UploadOut,
)


class OTPRequestIn(BaseModel):
    phone: str


class OTPVerifyIn(BaseModel):
    phone: str
    code: str


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: Optional[str] = None
    phone: str
    email: str
    gender: Optional[str] = Field(None, description="male|female")
    age: Optional[int] = None
    role: Role
    imageUrl: Optional[str] = None


class FcmTokenIn(BaseModel):
    """تحديث رمز FCM للمستخدم الحالي (للدفع من الخادم لاحقاً)."""

    fcm_token: str = Field(..., min_length=10, description="رمز FCM من FirebaseMessaging.getToken()")


class DentistRegisterIn(BaseModel):
    """إنشاء حساب: الاسم الثلاثي، الهاتف، البريد، العمر، الجنس (بعد التحقق من OTP على الهاتف)."""

    name: str = Field(..., min_length=2, description="الاسم الثلاثي")
    phone: str
    email: EmailStr
    age: int = Field(..., ge=1, le=120)
    gender: Literal["male", "female"]
