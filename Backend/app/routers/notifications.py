import logging
from typing import Annotated

from beanie import PydanticObjectId
from beanie.operators import Eq, Set
from fastapi import APIRouter, Depends, HTTPException, Query, Response, Security, status
from fastapi.security import APIKeyHeader

from app.config import get_settings
from app.constants import Role
from app.models.notification import InAppNotificationType, UserNotification
from app.models.user import User
from app.schemas.notifications import (
    AppAnnouncementCreateIn,
    NotificationCategoryQuery,
    UnreadCountOut,
    UserNotificationOut,
)
from app.security import get_current_user
from app.services.notification_service import create_app_announcements_for_recipients

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/notifications", tags=["notifications"])


def _to_out(n: UserNotification) -> UserNotificationOut:
    return UserNotificationOut(
        id=str(n.id),
        type=n.type,
        title=n.title,
        body=n.body,
        read=n.read,
        created_at=n.created_at,
        job_id=str(n.job_id) if n.job_id else None,
        job_title=n.job_title,
        actor_name=n.actor_name,
        application_status=n.application_status,
    )


@router.get("", response_model=list[UserNotificationOut])
async def list_notifications(
    category: NotificationCategoryQuery = Query(
        default=NotificationCategoryQuery.all,
        description="فلتر التبويب: all | job_posting_application | my_application_status | app_announcement",
    ),
    limit: int = Query(default=100, le=200, ge=1),
    current: User = Depends(get_current_user),
):
    """
    قائمة إشعارات المستخدم الحالي من الأحدث للأقدم.

    - **all**: كل الأنواع (مثل تبويب «الكل»).
    - **job_posting_application**: طلبات التقديم على وظائفك المنشورة.
    - **my_application_status**: تحديثات طلبات التوظيف التي قدّمتها.
    - **app_announcement**: أشعارات النظام من لوحة التحكم.
    """
    uid = PydanticObjectId(current.id)
    criteria: list = [UserNotification.recipient_id == uid]
    if category != NotificationCategoryQuery.all:
        criteria.append(
            UserNotification.type == InAppNotificationType(category.value),
        )
    notifs = (
        await UserNotification.find(*criteria)
        .sort(-UserNotification.created_at)
        .limit(limit)
        .to_list()
    )
    return [_to_out(n) for n in notifs]


@router.get("/unread-count", response_model=UnreadCountOut)
async def unread_count(current: User = Depends(get_current_user)):
    uid = PydanticObjectId(current.id)

    async def _cnt(t: InAppNotificationType | None) -> int:
        args: list = [
            UserNotification.recipient_id == uid,
            Eq(UserNotification.read, False),
        ]
        if t is not None:
            args.append(UserNotification.type == t)
        return await UserNotification.find(*args).count()

    total = await _cnt(None)
    job_app = await _cnt(InAppNotificationType.JOB_POSTING_APPLICATION)
    my_status = await _cnt(InAppNotificationType.MY_APPLICATION_STATUS)
    app_ann = await _cnt(InAppNotificationType.APP_ANNOUNCEMENT)
    return UnreadCountOut(
        total=total,
        by_category={
            "all": total,
            "job_posting_application": job_app,
            "my_application_status": my_status,
            "app_announcement": app_ann,
        },
    )


@router.patch("/{notification_id}/read", response_model=UserNotificationOut)
async def mark_notification_read(
    notification_id: str,
    current: User = Depends(get_current_user),
):
    try:
        oid = PydanticObjectId(notification_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid notification id")

    n = await UserNotification.get(oid)
    if not n or str(n.recipient_id) != str(current.id):
        raise HTTPException(status_code=404, detail="Notification not found")

    n.read = True
    await n.save()
    return _to_out(n)


@router.post("/read-all", status_code=status.HTTP_204_NO_CONTENT)
async def mark_all_read(
    category: NotificationCategoryQuery | None = Query(
        default=None,
        description="إن وُجد، يُعلِّم كمقروء ضمن هذا النوع فقط؛ وإلا كل الإشعارات",
    ),
    current: User = Depends(get_current_user),
):
    uid = PydanticObjectId(current.id)
    criteria: list = [
        UserNotification.recipient_id == uid,
        Eq(UserNotification.read, False),
    ]
    if category is not None and category != NotificationCategoryQuery.all:
        criteria.append(
            UserNotification.type == InAppNotificationType(category.value),
        )
    await UserNotification.find(*criteria).update(Set({UserNotification.read: True}))
    return Response(status_code=status.HTTP_204_NO_CONTENT)


_internal_notifications_api_key = APIKeyHeader(
    name="X-Internal-Notifications-Key",
    auto_error=False,
    description="قيمة INTERNAL_NOTIFICATIONS_KEY من .env فقط (مثلاً 123456) — لا تكتب اسم الرأس هنا",
)


def _normalize_dashboard_key(raw: str | None) -> str:
    if not raw:
        return ""
    s = raw.strip()
    prefix = "x-internal-notifications-key:"
    if s.lower().startswith(prefix):
        s = s[len(prefix) :].strip()
    return s


def _require_internal_key(
    api_key: Annotated[str | None, Security(_internal_notifications_api_key)] = None,
) -> None:
    settings = get_settings()
    expected = (settings.INTERNAL_NOTIFICATIONS_KEY or "").strip()
    if not expected:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="لم يُضبط INTERNAL_NOTIFICATIONS_KEY في الخادم",
        )
    received = _normalize_dashboard_key(api_key)
    if received != expected:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="مفتاح لوحة التحكم غير صالح",
        )


@router.post(
    "/app-announcement",
    status_code=status.HTTP_201_CREATED,
    summary="إنشاء أشعارات تطبيق (لوحة التحكم)",
    dependencies=[Depends(_require_internal_key)],
)
async def post_app_announcement(
    payload: AppAnnouncementCreateIn,
):
    """
    ينشئ إشعار `app_announcement`:
    - لكل معرف في `recipient_user_ids`، أو
    - لكل مستخدمي التطبيق عند تمرير `send_to_all=true`.
    أرسل الرأس: **X-Internal-Notifications-Key** بقيمة **INTERNAL_NOTIFICATIONS_KEY** من البيئة.
    """
    oids: list[PydanticObjectId] = []

    if payload.send_to_all:
        users = await User.find(User.role == Role.DENTIST).to_list()
        oids = [PydanticObjectId(u.id) for u in users]
    else:
        for raw in payload.recipient_user_ids or []:
            try:
                oids.append(PydanticObjectId(raw.strip()))
            except Exception:
                raise HTTPException(
                    status_code=400,
                    detail=f"معرف مستخدم غير صالح: {raw!r}",
                )
    try:
        n = await create_app_announcements_for_recipients(
            recipient_ids=oids,
            title=payload.title,
            body=payload.body,
        )
    except Exception:
        logger.exception("create_app_announcements_for_recipients")
        raise HTTPException(status_code=500, detail="تعذر حفظ الإشعارات")
    return {"created": n}
