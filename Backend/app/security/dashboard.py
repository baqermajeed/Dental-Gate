from typing import Annotated

from fastapi import Depends, HTTPException, Security, status
from fastapi.security import APIKeyHeader, HTTPAuthorizationCredentials, HTTPBearer

from app.config import get_settings
from app.models.user import User
from app.security import get_current_user
from app.services.auth_service import get_or_create_dashboard_admin_user

_bearer_optional = HTTPBearer(auto_error=False)
_dashboard_key_header = APIKeyHeader(
    name="X-Internal-Dashboard-Key",
    auto_error=False,
    description="مفتاح لوحة التحكم من .env (INTERNAL_DASHBOARD_KEY أو INTERNAL_NOTIFICATIONS_KEY)",
)


def _expected_dashboard_key() -> str:
    settings = get_settings()
    return (
        (settings.INTERNAL_DASHBOARD_KEY or settings.INTERNAL_NOTIFICATIONS_KEY or "")
        .strip()
    )


async def get_slider_manager(
    credentials: Annotated[
        HTTPAuthorizationCredentials | None, Depends(_bearer_optional)
    ] = None,
    dashboard_key: Annotated[str | None, Security(_dashboard_key_header)] = None,
) -> User:
    """JWT لأي مستخدم مسجّل، أو مفتاح داخلي لحساب المدير (لوحة التحكم)."""
    expected = _expected_dashboard_key()
    received = (dashboard_key or "").strip()
    if expected and received == expected:
        return await get_or_create_dashboard_admin_user()

    if credentials and credentials.credentials:
        return await get_current_user(credentials)

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="يجب تسجيل الدخول أو إرسال مفتاح لوحة التحكم الصحيح",
    )
