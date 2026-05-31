from collections import Counter
from datetime import datetime, timedelta, timezone

from beanie import PydanticObjectId
from beanie.operators import In
from fastapi import APIRouter, Depends, HTTPException, Query, Response, status

from app.constants import Role
from app.models.doctor_peer_rating import DoctorPeerRating
from app.models.doctor_profile import (
    DoctorProfile,
    PracticeLicenseStatus,
)
from app.models.job import JobApplication, JobPosting, JobRequestStatus
from app.models.notification import InAppNotificationType, UserNotification
from app.models.saved_doctor import SavedDoctor
from app.models.saved_job import SavedJob
from app.models.user import User
from app.schemas.admin_dashboard import (
    AccreditedCourseReviewItemOut,
    AdminJobListItemOut,
    AdminUserListItemOut,
    AnnouncementLogItemOut,
    DashboardKpiOut,
    DashboardOverviewOut,
    JobStatusUpdateIn,
    PaginatedAdminJobsOut,
    PaginatedAdminUsersOut,
    PracticeLicenseReviewItemOut,
    ReviewDecisionIn,
    VerificationQueueOut,
)
from app.security import require_admin
from app.services import experience_score_service as experience_score_svc
from app.services.otp_service import iraqi_phone_for_display

router = APIRouter(
    prefix="/admin-dashboard",
    tags=["admin-dashboard"],
    dependencies=[Depends(require_admin)],
)


def _normalize_text(value: str | None) -> str:
    return (value or "").strip()


@router.get("/overview", response_model=DashboardOverviewOut)
async def get_dashboard_overview():
    now = datetime.now(timezone.utc)
    from_30_days = now - timedelta(days=30)

    dentists = await User.find(User.role == Role.DENTIST).to_list()
    dentist_ids = [PydanticObjectId(user.id) for user in dentists]

    jobs = await JobPosting.find_all().to_list()
    applications = await JobApplication.find_all().to_list()
    if dentist_ids:
        profiles = await DoctorProfile.find(In(DoctorProfile.user_id, dentist_ids)).to_list()
    else:
        profiles = []
    notifications = await UserNotification.find_all().to_list()
    peer_ratings = await DoctorPeerRating.find_all().to_list()

    jobs_by_status = Counter(job.status.value for job in jobs)
    applications_by_status = Counter(app.status.value for app in applications)

    users_by_governorate = Counter()
    users_by_professional_title = Counter()
    users_by_tier = Counter()

    pending_practice_licenses = 0
    pending_courses = 0
    profile_map = {str(p.user_id): p for p in profiles}

    for profile in profiles:
        gov = _normalize_text(profile.governorate) or "غير محدد"
        title = _normalize_text(profile.professional_title) or "غير محدد"
        users_by_governorate[gov] += 1
        users_by_professional_title[title] += 1

        if profile.experience_score:
            users_by_tier[profile.experience_score.tier.value] += 1
        else:
            users_by_tier["silver"] += 1

        if (
            profile.practice_license
            and profile.practice_license.status == PracticeLicenseStatus.PENDING
        ):
            pending_practice_licenses += 1

        pending_courses += sum(
            1
            for course in profile.accredited_courses
            if course.status == PracticeLicenseStatus.PENDING
        )

    active_jobs = 0
    expired_jobs = 0
    for job in jobs:
        if job.application_deadline and job.application_deadline < now:
            expired_jobs += 1
        else:
            active_jobs += 1

    unread_notifications = sum(1 for n in notifications if not n.read)
    avg_peer_rating = (
        round(sum(r.stars for r in peer_ratings) / len(peer_ratings), 2)
        if peer_ratings
        else 0
    )

    kpis = DashboardKpiOut(
        total_dentists=len(dentists),
        new_dentists_last_30_days=sum(1 for d in dentists if d.created_at >= from_30_days),
        dentists_with_fcm=sum(1 for d in dentists if _normalize_text(d.fcm_token)),
        total_jobs=len(jobs),
        active_jobs=active_jobs,
        expired_jobs=expired_jobs,
        total_applications=len(applications),
        pending_applications=applications_by_status.get(JobRequestStatus.PENDING.value, 0),
        accepted_applications=applications_by_status.get(
            JobRequestStatus.ACCEPTED.value, 0
        ),
        rejected_applications=applications_by_status.get(
            JobRequestStatus.REJECTED.value, 0
        ),
        pending_practice_licenses=pending_practice_licenses,
        pending_courses=pending_courses,
        unread_notifications=unread_notifications,
        total_peer_ratings=len(peer_ratings),
        avg_peer_rating=avg_peer_rating,
    )

    return DashboardOverviewOut(
        generated_at=now,
        kpis=kpis,
        jobs_by_status=dict(jobs_by_status),
        applications_by_status=dict(applications_by_status),
        users_by_governorate=dict(users_by_governorate),
        users_by_professional_title=dict(users_by_professional_title),
        users_by_tier=dict(users_by_tier),
    )


@router.get("/users", response_model=PaginatedAdminUsersOut)
async def list_admin_users(
    q: str = Query(default="", description="بحث بالاسم أو الهاتف أو البريد"),
    governorate: str = Query(default="", description="فلتر المحافظة"),
    professional_title: str = Query(default="", description="فلتر التخصص"),
    limit: int = Query(default=25, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
):
    users = await User.find(User.role == Role.DENTIST).sort(-User.created_at).to_list()
    user_ids = [PydanticObjectId(u.id) for u in users]
    if user_ids:
        profiles = await DoctorProfile.find(In(DoctorProfile.user_id, user_ids)).to_list()
    else:
        profiles = []
    profile_map = {str(p.user_id): p for p in profiles}

    if user_ids:
        jobs = await JobPosting.find(In(JobPosting.posted_by, user_ids)).to_list()
        applications = await JobApplication.find(
            In(JobApplication.applicant_id, user_ids)
        ).to_list()
        saved_jobs = await SavedJob.find(In(SavedJob.user_id, user_ids)).to_list()
        saved_doctors = await SavedDoctor.find(
            In(SavedDoctor.user_id, user_ids)
        ).to_list()
    else:
        jobs = []
        applications = []
        saved_jobs = []
        saved_doctors = []

    jobs_count = Counter(str(job.posted_by) for job in jobs)
    applications_count = Counter(str(app.applicant_id) for app in applications)
    saved_jobs_count = Counter(str(item.user_id) for item in saved_jobs)
    saved_doctors_count = Counter(str(item.user_id) for item in saved_doctors)

    query = _normalize_text(q).lower()
    governorate_filter = _normalize_text(governorate).lower()
    title_filter = _normalize_text(professional_title).lower()

    items: list[AdminUserListItemOut] = []
    for user in users:
        profile = profile_map.get(str(user.id))
        gov = _normalize_text(profile.governorate if profile else None)
        title = _normalize_text(profile.professional_title if profile else None)

        haystack = " ".join(
            [
                _normalize_text(user.name),
                _normalize_text(user.phone),
                _normalize_text(user.email),
                gov,
                title,
            ]
        ).lower()

        if query and query not in haystack:
            continue
        if governorate_filter and governorate_filter != gov.lower():
            continue
        if title_filter and title_filter != title.lower():
            continue

        items.append(
            AdminUserListItemOut(
                id=str(user.id),
                name=user.name,
                phone=iraqi_phone_for_display(user.phone),
                email=user.email,
                gender=user.gender,
                age=user.age,
                governorate=gov or None,
                professional_title=title or None,
                years_experience=profile.years_experience if profile else None,
                experience_tier=profile.experience_score.tier
                if profile and profile.experience_score
                else None,
                jobs_posted_count=jobs_count.get(str(user.id), 0),
                applications_count=applications_count.get(str(user.id), 0),
                saved_jobs_count=saved_jobs_count.get(str(user.id), 0),
                saved_doctors_count=saved_doctors_count.get(str(user.id), 0),
                created_at=user.created_at,
            )
        )

    total = len(items)
    paginated = items[offset : offset + limit]
    return PaginatedAdminUsersOut(items=paginated, total=total, limit=limit, offset=offset)


@router.get("/verifications", response_model=VerificationQueueOut)
async def get_verification_queue(
    status_filter: PracticeLicenseStatus | None = Query(
        default=PracticeLicenseStatus.PENDING
    ),
):
    users = await User.find(User.role == Role.DENTIST).to_list()
    user_map = {str(user.id): user for user in users}
    profiles = await DoctorProfile.find_all().to_list()

    practice_items: list[PracticeLicenseReviewItemOut] = []
    course_items: list[AccreditedCourseReviewItemOut] = []

    for profile in profiles:
        user = user_map.get(str(profile.user_id))
        if not user:
            continue

        if profile.practice_license:
            license_item = profile.practice_license
            if status_filter is None or license_item.status == status_filter:
                practice_items.append(
                    PracticeLicenseReviewItemOut(
                        user_id=str(user.id),
                        user_name=user.name,
                        user_phone=iraqi_phone_for_display(user.phone),
                        governorate=profile.governorate,
                        professional_title=profile.professional_title,
                        image_url=license_item.image_url,
                        explanation=license_item.explanation,
                        status=license_item.status,
                        rejection_reason=license_item.rejection_reason,
                        submitted_at=license_item.submitted_at,
                        reviewed_at=license_item.reviewed_at,
                    )
                )

        for course in profile.accredited_courses:
            if status_filter is not None and course.status != status_filter:
                continue
            course_items.append(
                AccreditedCourseReviewItemOut(
                    user_id=str(user.id),
                    user_name=user.name,
                    user_phone=iraqi_phone_for_display(user.phone),
                    governorate=profile.governorate,
                    professional_title=profile.professional_title,
                    course_id=course.id,
                    title=course.title,
                    image_url=course.image_url,
                    explanation=course.explanation,
                    status=course.status,
                    points_awarded=course.points_awarded,
                    rejection_reason=course.rejection_reason,
                    submitted_at=course.submitted_at,
                    reviewed_at=course.reviewed_at,
                )
            )

    practice_items.sort(key=lambda x: x.submitted_at, reverse=True)
    course_items.sort(key=lambda x: x.submitted_at, reverse=True)
    return VerificationQueueOut(
        practice_licenses=practice_items,
        accredited_courses=course_items,
    )


@router.patch("/verifications/practice-license/{user_id}")
async def review_practice_license(
    user_id: str,
    payload: ReviewDecisionIn,
):
    if payload.decision == PracticeLicenseStatus.PENDING:
        raise HTTPException(status_code=400, detail="decision must be approved or rejected")

    try:
        uid = PydanticObjectId(user_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid user id")

    profile = await DoctorProfile.find_one(DoctorProfile.user_id == uid)
    if not profile or not profile.practice_license:
        raise HTTPException(status_code=404, detail="Practice license not found")

    profile.practice_license.status = payload.decision
    profile.practice_license.reviewed_at = datetime.now(timezone.utc)
    profile.practice_license.rejection_reason = (
        _normalize_text(payload.rejection_reason) if payload.decision == PracticeLicenseStatus.REJECTED else None
    )
    profile.updated_at = datetime.now(timezone.utc)
    await profile.save()
    await experience_score_svc.recompute_and_persist_for_user(uid)
    return {"status": "ok"}


@router.patch("/verifications/accredited-courses/{user_id}/{course_id}")
async def review_accredited_course(
    user_id: str,
    course_id: str,
    payload: ReviewDecisionIn,
):
    if payload.decision == PracticeLicenseStatus.PENDING:
        raise HTTPException(status_code=400, detail="decision must be approved or rejected")

    try:
        uid = PydanticObjectId(user_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid user id")

    profile = await DoctorProfile.find_one(DoctorProfile.user_id == uid)
    if not profile:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    course = next((c for c in profile.accredited_courses if c.id == course_id), None)
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")

    course.status = payload.decision
    course.reviewed_at = datetime.now(timezone.utc)
    if payload.decision == PracticeLicenseStatus.APPROVED:
        course.points_awarded = 2
        course.rejection_reason = None
    else:
        course.points_awarded = 0
        course.rejection_reason = _normalize_text(payload.rejection_reason)

    profile.updated_at = datetime.now(timezone.utc)
    await profile.save()
    await experience_score_svc.recompute_and_persist_for_user(uid)
    return {"status": "ok"}


@router.get("/jobs", response_model=PaginatedAdminJobsOut)
async def list_admin_jobs(
    q: str = Query(default="", description="بحث باسم مكان العمل/العنوان/التخصص"),
    status_filter: JobRequestStatus | None = Query(default=None),
    limit: int = Query(default=25, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
):
    jobs = await JobPosting.find_all().sort(-JobPosting.created_at).to_list()
    job_ids = [PydanticObjectId(job.id) for job in jobs]
    poster_ids = [PydanticObjectId(job.posted_by) for job in jobs]

    if job_ids:
        applications = await JobApplication.find(In(JobApplication.job_id, job_ids)).to_list()
    else:
        applications = []
    if poster_ids:
        users = await User.find(In(User.id, poster_ids)).to_list()
    else:
        users = []
    user_map = {str(u.id): u for u in users}

    applications_by_job = Counter(str(app.job_id) for app in applications)
    accepted_by_job = Counter(
        str(app.job_id)
        for app in applications
        if app.status == JobRequestStatus.ACCEPTED
    )
    pending_by_job = Counter(
        str(app.job_id)
        for app in applications
        if app.status == JobRequestStatus.PENDING
    )
    rejected_by_job = Counter(
        str(app.job_id)
        for app in applications
        if app.status == JobRequestStatus.REJECTED
    )

    query = _normalize_text(q).lower()
    items: list[AdminJobListItemOut] = []
    for job in jobs:
        if status_filter is not None and job.status != status_filter:
            continue
        haystack = " ".join(
            [
                _normalize_text(job.workplace_name),
                _normalize_text(job.workplace_address),
                _normalize_text(job.required_specialty),
            ]
        ).lower()
        if query and query not in haystack:
            continue

        poster = user_map.get(str(job.posted_by))
        items.append(
            AdminJobListItemOut(
                id=str(job.id),
                workplace_name=job.workplace_name,
                workplace_address=job.workplace_address,
                required_specialty=job.required_specialty,
                years_experience=job.years_experience,
                monthly_salary_iqd=job.monthly_salary_iqd,
                shift_hours=job.shift_hours,
                working_hours=job.working_hours,
                description=job.description,
                status=job.status,
                posted_by=str(job.posted_by),
                poster_name=poster.name if poster else None,
                created_at=job.created_at,
                updated_at=job.updated_at,
                application_deadline=job.application_deadline,
                applications_count=applications_by_job.get(str(job.id), 0),
                accepted_count=accepted_by_job.get(str(job.id), 0),
                pending_count=pending_by_job.get(str(job.id), 0),
                rejected_count=rejected_by_job.get(str(job.id), 0),
            )
        )

    total = len(items)
    paginated = items[offset : offset + limit]
    return PaginatedAdminJobsOut(items=paginated, total=total, limit=limit, offset=offset)


@router.patch("/jobs/{job_id}/status")
async def update_job_status(
    job_id: str,
    payload: JobStatusUpdateIn,
):
    try:
        oid = PydanticObjectId(job_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid job id")

    job = await JobPosting.get(oid)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    job.status = payload.status
    job.updated_at = datetime.now(timezone.utc)
    await job.save()
    return {"status": "ok"}


@router.delete("/jobs/{job_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_job_by_admin(job_id: str):
    try:
        oid = PydanticObjectId(job_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid job id")

    job = await JobPosting.get(oid)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    await JobApplication.find(JobApplication.job_id == oid).delete()
    await job.delete()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/notifications/announcements", response_model=list[AnnouncementLogItemOut])
async def list_announcement_logs(limit: int = Query(default=50, ge=1, le=500)):
    notifications = (
        await UserNotification.find(
            UserNotification.type == InAppNotificationType.APP_ANNOUNCEMENT
        )
        .sort(-UserNotification.created_at)
        .limit(5000)
        .to_list()
    )

    grouped: dict[str, AnnouncementLogItemOut] = {}
    for item in notifications:
        key = (
            f"{item.created_at.isoformat()}::{item.title.strip()}::{item.body.strip()}"
        )
        if key not in grouped:
            grouped[key] = AnnouncementLogItemOut(
                created_at=item.created_at,
                title=item.title,
                body=item.body,
                recipients_count=1,
            )
        else:
            grouped[key].recipients_count += 1

    result = sorted(grouped.values(), key=lambda x: x.created_at, reverse=True)
    return result[:limit]
