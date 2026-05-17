"""إرسال إشعارات الدفع عبر Firebase Cloud Messaging (يتطلب ملف Service Account)."""

from __future__ import annotations

import asyncio
import logging
import os
from typing import Any

import firebase_admin
from beanie import PydanticObjectId
from firebase_admin import credentials, messaging

from app.config import get_settings
from app.models.user import User

logger = logging.getLogger(__name__)

_firebase_config_warned = False


def _ensure_firebase_app() -> bool:
    global _firebase_config_warned
    if firebase_admin._apps:
        return True
    path = (get_settings().FIREBASE_SERVICE_ACCOUNT_JSON or "").strip()
    if not path or not os.path.isfile(path):
        if not _firebase_config_warned:
            _firebase_config_warned = True
            logger.warning(
                "FIREBASE_SERVICE_ACCOUNT_JSON غير مضبوط أو الملف غير موجود — لن تُرسل إشعارات الدفع. "
                "أضف في .env مسار ملف JSON من Firebase Console → Project settings → Service accounts",
            )
        return False
    try:
        cred = credentials.Certificate(path)
        firebase_admin.initialize_app(cred)
        return True
    except Exception:
        logger.exception("فشل تهيئة Firebase Admin لـ FCM")
        return False


def _send_fcm_sync(
    token: str,
    title: str,
    body: str,
    data: dict[str, str] | None,
) -> None:
    msg = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        token=token,
        data=data or {},
    )
    messaging.send(msg)


async def send_push_to_user(
    *,
    recipient_id: PydanticObjectId,
    title: str,
    body: str,
    data: dict[str, Any] | None = None,
) -> None:
    """يرسل دفع FCM إن وُجد fcm_token للمستخدم وملف الخدمة مهيأ."""
    if not _ensure_firebase_app():
        return
    user = await User.get(recipient_id)
    if not user or not user.fcm_token or not user.fcm_token.strip():
        logger.info(
            "FCM: لا يوجد fcm_token للمستخدم %s — افتح التطبيق بعد تسجيل الدخول ليُسجَّل التوكن",
            recipient_id,
        )
        return
    str_data: dict[str, str] | None = None
    if data:
        str_data = {k: str(v) for k, v in data.items() if v is not None}
    try:
        await asyncio.to_thread(
            _send_fcm_sync,
            user.fcm_token.strip(),
            title[:200],
            body[:2000],
            str_data,
        )
    except Exception:
        logger.exception("فشل إرسال FCM للمستخدم %s", recipient_id)
