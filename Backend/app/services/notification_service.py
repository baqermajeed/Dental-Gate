import logging
from datetime import datetime, timezone

from beanie import PydanticObjectId

from app.models.job import JobPosting
from app.models.notification import InAppNotificationType, UserNotification
from app.models.user import User
from app.services.fcm_push_service import send_push_to_user

logger = logging.getLogger(__name__)


def display_user_name(user: User) -> str:
    if user.name and user.name.strip():
        return user.name.strip()
    return user.phone or "مستخدم"


def job_notification_title(job: JobPosting) -> str:
    return f"{job.workplace_name} ({job.required_specialty})"


async def notify_new_application_on_my_job(
    *,
    job: JobPosting,
    applicant: User,
    application_id: PydanticObjectId,
) -> None:
    actor = display_user_name(applicant)
    jt = job_notification_title(job)
    n = UserNotification(
        recipient_id=job.posted_by,
        type=InAppNotificationType.JOB_POSTING_APPLICATION,
        title="طلب جديد",
        body=f"قام {actor} بالتقديم على الوظيفة التي نشرتها",
        read=False,
        job_id=job.id,
        job_title=jt,
        actor_name=actor,
        related_application_id=application_id,
        created_at=datetime.now(timezone.utc),
    )
    await n.insert()
    try:
        await send_push_to_user(
            recipient_id=job.posted_by,
            title=n.title,
            body=n.body,
            data={"notification_id": str(n.id), "type": n.type.value},
        )
    except Exception:
        logger.exception("FCM after job application notification")


async def notify_application_status_to_applicant(
    *,
    applicant_id: PydanticObjectId,
    job: JobPosting,
    application_id: PydanticObjectId,
    status: str,
) -> None:
    jt = job_notification_title(job)
    if status == "accepted":
        title = "تم قبول طلبك"
        body = f"تم قبولك في الوظيفة: {jt}"
    elif status == "rejected":
        title = "لم يتم القبول"
        body = f"لم يتم قبولك في الوظيفة: {jt}"
    else:
        title = "تحديث طلب التوظيف"
        body = f"تحديث بخصوص الوظيفة: {jt}"

    n = UserNotification(
        recipient_id=applicant_id,
        type=InAppNotificationType.MY_APPLICATION_STATUS,
        title=title,
        body=body,
        read=False,
        job_id=job.id,
        job_title=jt,
        application_status=status,
        related_application_id=application_id,
        created_at=datetime.now(timezone.utc),
    )
    await n.insert()
    try:
        await send_push_to_user(
            recipient_id=applicant_id,
            title=n.title,
            body=n.body,
            data={"notification_id": str(n.id), "type": n.type.value},
        )
    except Exception:
        logger.exception("FCM after application status notification")


async def create_app_announcements_for_recipients(
    *,
    recipient_ids: list[PydanticObjectId],
    title: str,
    body: str,
) -> int:
    now = datetime.now(timezone.utc)
    count = 0
    seen: set[PydanticObjectId] = set()
    for rid in recipient_ids:
        if rid in seen:
            continue
        seen.add(rid)
        n = UserNotification(
            recipient_id=rid,
            type=InAppNotificationType.APP_ANNOUNCEMENT,
            title=title.strip(),
            body=body.strip(),
            read=False,
            created_at=now,
        )
        await n.insert()
        count += 1
        try:
            await send_push_to_user(
                recipient_id=rid,
                title=n.title,
                body=n.body,
                data={"notification_id": str(n.id), "type": n.type.value},
            )
        except Exception:
            logger.exception("FCM after app announcement for %s", rid)
    return count
