from datetime import datetime, timezone

from fastapi import APIRouter, Body, Depends, Request, status

from app.rate_limit import limiter
from app.schemas import (
    AdminLoginIn,
    DentistRegisterIn,
    FcmTokenIn,
    OTPRequestIn,
    OTPVerifyIn,
    Token,
    UserOut,
)
from app.models.user import User
from app.security import create_access_token, create_refresh_token, get_current_user
from app.services.auth_service import (
    admin_login,
    create_dentist_account,
    refresh_access_token,
    request_otp,
    verify_otp_and_login,
)
from app.services.account_delete_service import delete_user_and_all_related_data
from app.services.otp_service import iraqi_phone_for_display

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/request-otp")
@limiter.limit("5/minute")
async def route_request_otp(request: Request, payload: OTPRequestIn):
    """طلب إرسال رمز تحقق OTP إلى رقم الهاتف (نفس مسار ومعدل backend_farah)."""
    await request_otp(payload.phone)
    return {"status": "sent"}


@router.post("/admin-login", response_model=Token)
@limiter.limit("10/minute")
async def route_admin_login(request: Request, payload: AdminLoginIn):
    """تسجيل دخول لوحة التحكم (اسم مستخدم + كلمة مرور للمدير فقط)."""
    access_token, refresh_token, _user = await admin_login(
        username=payload.username,
        password=payload.password,
    )
    return Token(access_token=access_token, refresh_token=refresh_token)


@router.post("/verify-otp")
@limiter.limit("10/minute")
async def route_verify_otp(request: Request, payload: OTPVerifyIn):
    """التحقق من رمز OTP — إن وُجد حساب يُعاد التوكن، وإلا account_exists: false."""
    tokens, user = await verify_otp_and_login(phone=payload.phone, code=payload.code)

    if tokens is None or user is None:
        return {"account_exists": False}

    access_token, refresh_token = tokens
    return {
        "account_exists": True,
        "token": Token(
            access_token=access_token,
            refresh_token=refresh_token,
        ).model_dump(),
    }


@router.post("/register", response_model=Token)
@limiter.limit("5/minute")
async def route_register(request: Request, payload: DentistRegisterIn):
    """إنشاء حساب طبيب جديد (بعد إرسال OTP والتحقق منه عبر verify-otp)."""
    user = await create_dentist_account(
        name=payload.name,
        phone=payload.phone,
        email=str(payload.email),
        age=payload.age,
        gender=payload.gender,
    )
    token_data = {
        "sub": str(user.id),
        "role": user.role.value,
        "phone": user.phone,
        "email": user.email,
    }
    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)
    return Token(access_token=access_token, refresh_token=refresh_token)


@router.post("/refresh", response_model=Token)
async def route_refresh(refresh_token: str = Body(..., embed=True)):
    new_access, new_refresh = await refresh_access_token(refresh_token)
    return Token(access_token=new_access, refresh_token=new_refresh)


@router.get("/me", response_model=UserOut)
async def route_me(current: User = Depends(get_current_user)):
    return UserOut(
        id=str(current.id),
        name=current.name,
        phone=iraqi_phone_for_display(current.phone),
        email=current.email,
        gender=current.gender,
        age=current.age,
        role=current.role,
        imageUrl=current.imageUrl,
    )


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
@limiter.limit("10/minute")
async def delete_my_account(
    request: Request,
    current: User = Depends(get_current_user),
):
    """حذف الحساب نهائياً مع كل البيانات المرتبطة (بروفايل، وظائف، طلبات، إشعارات، …)."""
    await delete_user_and_all_related_data(current)
    return None


@router.patch("/me/fcm-token")
async def patch_me_fcm_token(
    payload: FcmTokenIn,
    current: User = Depends(get_current_user),
):
    """يخزّن رمز FCM في MongoDB (بدون Firestore). لإرسال الدفع استخدم Admin SDK من الخادم."""
    now = datetime.now(timezone.utc)
    current.fcm_token = payload.fcm_token.strip()
    current.fcm_token_updated_at = now
    current.updated_at = now
    await current.save()
    return {"status": "ok"}
