import logging
from datetime import datetime, timezone

from beanie import PydanticObjectId
from fastapi import APIRouter, Depends, HTTPException, status

from app.models.doctor_profile import DoctorProfile
from app.models.job import JobApplication, JobPosting
from app.models.user import User
from app.schemas.doctor_profile import DoctorProfileFullOut
from app.schemas.jobs import (
    JobApplicantItemOut,
    JobApplicationCountOut,
    JobApplicationDecisionIn,
    JobApplicationOut,
    JobPostingCreateIn,
    JobPostingOut,
    MyJobApplicationOut,
)
from app.security import get_current_user
from app.services import doctor_profile_service as profile_svc
from app.utils.datetime_utils import ensure_utc
from app.services.notification_service import (
    notify_application_status_to_applicant,
    notify_new_application_on_my_job,
)
from app.services.otp_service import iraqi_phone_for_display

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/jobs", tags=["jobs"])


def _job_to_out(job: JobPosting) -> JobPostingOut:
    return JobPostingOut(
        id=str(job.id),
        posted_by=str(job.posted_by),
        workplace_name=job.workplace_name,
        workplace_address=job.workplace_address,
        required_specialty=job.required_specialty,
        years_experience=job.years_experience,
        monthly_salary_iqd=job.monthly_salary_iqd,
        shift_hours=job.shift_hours,
        working_hours=job.working_hours,
        description=job.description,
        education=job.education,
        languages=job.languages,
        core_skills=job.core_skills,
        application_deadline=job.application_deadline,
        status=job.status,
        created_at=job.created_at,
        updated_at=job.updated_at,
    )


def _application_to_out(apply: JobApplication) -> JobApplicationOut:
    return JobApplicationOut(
        id=str(apply.id),
        job_id=str(apply.job_id),
        applicant_id=str(apply.applicant_id),
        status=apply.status,
        created_at=apply.created_at,
        updated_at=apply.updated_at,
    )


@router.post("", response_model=JobPostingOut, status_code=status.HTTP_201_CREATED)
async def create_job_posting(
    payload: JobPostingCreateIn,
    current: User = Depends(get_current_user),
):
    now = datetime.now(timezone.utc)
    job = JobPosting(
        posted_by=PydanticObjectId(current.id),
        workplace_name=payload.workplace_name,
        workplace_address=payload.workplace_address,
        required_specialty=payload.required_specialty,
        years_experience=payload.years_experience,
        monthly_salary_iqd=payload.monthly_salary_iqd,
        shift_hours=payload.shift_hours,
        working_hours=payload.working_hours,
        description=payload.description,
        education=payload.education,
        languages=payload.languages,
        core_skills=payload.core_skills,
        application_deadline=ensure_utc(payload.application_deadline),
        created_at=now,
        updated_at=now,
    )
    await job.insert()
    return _job_to_out(job)


@router.get("", response_model=list[JobPostingOut])
async def list_job_postings():
    now = datetime.now(timezone.utc)
    jobs = await JobPosting.find_all().sort(-JobPosting.created_at).to_list()
    active: list[JobPosting] = []
    for j in jobs:
        deadline = ensure_utc(j.application_deadline)
        if deadline is None or deadline >= now:
            active.append(j)
    jobs = active
    return [_job_to_out(j) for j in jobs]


@router.get("/mine", response_model=list[JobPostingOut])
async def list_my_posted_jobs(
    current: User = Depends(get_current_user),
):
    uid = PydanticObjectId(current.id)
    jobs = (
        await JobPosting.find(JobPosting.posted_by == uid)
        .sort(-JobPosting.created_at)
        .to_list()
    )
    return [_job_to_out(j) for j in jobs]


@router.get("/{job_id}", response_model=JobPostingOut)
async def get_job_posting(job_id: str):
    try:
        oid = PydanticObjectId(job_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid job id")

    job = await JobPosting.get(oid)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    return _job_to_out(job)


@router.patch("/{job_id}", response_model=JobPostingOut)
async def update_job_posting(
    job_id: str,
    payload: JobPostingCreateIn,
    current: User = Depends(get_current_user),
):
    """صاحب الإعلان: تحديث بيانات الوظيفة المنشورة."""
    try:
        oid = PydanticObjectId(job_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid job id")

    job = await JobPosting.get(oid)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    if str(job.posted_by) != str(current.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="ليس لديك صلاحية تعديل هذه الوظيفة",
        )

    now = datetime.now(timezone.utc)
    job.workplace_name = payload.workplace_name
    job.workplace_address = payload.workplace_address
    job.required_specialty = payload.required_specialty
    job.years_experience = payload.years_experience
    job.monthly_salary_iqd = payload.monthly_salary_iqd
    job.shift_hours = payload.shift_hours
    job.working_hours = payload.working_hours
    job.description = payload.description
    job.education = payload.education
    job.languages = payload.languages
    job.core_skills = payload.core_skills
    job.application_deadline = ensure_utc(payload.application_deadline)
    job.updated_at = now
    await job.save()
    return _job_to_out(job)


@router.delete("/{job_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_job_posting(
    job_id: str,
    current: User = Depends(get_current_user),
):
    """صاحب الإعلان: حذف الوظيفة نهائياً."""
    try:
        oid = PydanticObjectId(job_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid job id")

    job = await JobPosting.get(oid)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    if str(job.posted_by) != str(current.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="ليس لديك صلاحية حذف هذه الوظيفة",
        )

    await JobApplication.find(JobApplication.job_id == oid).delete()
    await job.delete()
    return None


@router.get(
    "/{job_id}/applications/count",
    response_model=JobApplicationCountOut,
)
async def count_applications_for_my_job(
    job_id: str,
    current: User = Depends(get_current_user),
):
    """صاحب الإعلان: عدد المتقدمين على الوظيفة."""
    try:
        job_oid = PydanticObjectId(job_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid job id")

    job = await JobPosting.get(job_oid)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    if str(job.posted_by) != str(current.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="ليس لديك صلاحية عرض طلبات هذه الوظيفة",
        )

    count = await JobApplication.find(JobApplication.job_id == job_oid).count()
    return JobApplicationCountOut(count=count)


@router.get(
    "/{job_id}/applications",
    response_model=list[JobApplicantItemOut],
)
async def list_job_applications_for_owner(
    job_id: str,
    current: User = Depends(get_current_user),
):
    """صاحب الإعلان: قائمة المتقدمين مع بيانات أساسية للبطاقة."""
    try:
        job_oid = PydanticObjectId(job_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid job id")

    job = await JobPosting.get(job_oid)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    if str(job.posted_by) != str(current.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="ليس لديك صلاحية عرض طلبات هذه الوظيفة",
        )

    applications = (
        await JobApplication.find(JobApplication.job_id == job_oid)
        .sort(-JobApplication.created_at)
        .to_list()
    )
    out: list[JobApplicantItemOut] = []
    for app in applications:
        u = await User.get(app.applicant_id)
        if not u:
            continue
        dp = await DoctorProfile.find_one(DoctorProfile.user_id == app.applicant_id)
        years = dp.years_experience if dp else None
        gov = (dp.governorate or "").strip() if dp and dp.governorate else ""
        title: str | None = None
        if dp and dp.bio and (t := dp.bio.strip()):
            title = t[:120] if len(t) > 120 else t
        if not title:
            title = "طبيب أسنان متدرب"
        out.append(
            JobApplicantItemOut(
                application_id=str(app.id),
                status=app.status,
                user_id=str(u.id),
                name=u.name,
                phone=iraqi_phone_for_display(u.phone),
                email=u.email,
                image_url=u.imageUrl,
                years_experience=years,
                governorate=gov or None,
                professional_title=title,
            )
        )
    return out


@router.get(
    "/{job_id}/applications/{application_id}/profile",
    response_model=DoctorProfileFullOut,
)
async def get_applicant_profile_for_job_owner(
    job_id: str,
    application_id: str,
    current: User = Depends(get_current_user),
):
    """صاحب الإعلان: بروفايل المتقدّم (نفس بنية ``GET /profile/me``)."""
    try:
        job_oid = PydanticObjectId(job_id)
        app_oid = PydanticObjectId(application_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid id")

    job = await JobPosting.get(job_oid)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    if str(job.posted_by) != str(current.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="ليس لديك صلاحية عرض هذا الطلب",
        )

    application = await JobApplication.get(app_oid)
    if not application or application.job_id != job_oid:
        raise HTTPException(status_code=404, detail="Application not found")

    applicant = await User.get(application.applicant_id)
    if not applicant:
        raise HTTPException(status_code=404, detail="Applicant not found")

    return await profile_svc.get_merged_profile_for_user(applicant)


@router.get("/applications/me", response_model=list[MyJobApplicationOut])
async def list_my_job_applications(
    current: User = Depends(get_current_user),
):
    """وظائف قدّم الطبيب عليها، من الأحدث إلى الأقدم."""
    uid = PydanticObjectId(current.id)
    applications = (
        await JobApplication.find(JobApplication.applicant_id == uid)
        .sort(-JobApplication.created_at)
        .to_list()
    )
    out: list[MyJobApplicationOut] = []
    for a in applications:
        job = await JobPosting.get(a.job_id)
        if not job:
            continue
        out.append(
            MyJobApplicationOut(
                id=str(a.id),
                status=a.status,
                created_at=a.created_at,
                updated_at=a.updated_at,
                job=_job_to_out(job),
            )
        )
    return out


@router.post(
    "/{job_id}/apply",
    response_model=JobApplicationOut,
    status_code=status.HTTP_201_CREATED,
)
async def apply_to_job(
    job_id: str,
    current: User = Depends(get_current_user),
):
    try:
        oid = PydanticObjectId(job_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid job id")

    job = await JobPosting.get(oid)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    if str(job.posted_by) == str(current.id):
        raise HTTPException(
            status_code=400,
            detail="لا يمكن التقديم على وظيفة قمت بنشرها",
        )
    now = datetime.now(timezone.utc)
    deadline = ensure_utc(job.application_deadline)
    if deadline is not None and deadline < now:
        raise HTTPException(
            status_code=400,
            detail="انتهى موعد التقديم على هذه الوظيفة",
        )

    existing = await JobApplication.find_one(
        JobApplication.job_id == oid,
        JobApplication.applicant_id == PydanticObjectId(current.id),
    )
    if existing:
        raise HTTPException(status_code=409, detail="تم التقديم مسبقاً على هذه الوظيفة")

    application = JobApplication(
        job_id=oid,
        applicant_id=PydanticObjectId(current.id),
        created_at=now,
        updated_at=now,
    )
    await application.insert()
    try:
        applicant = await User.get(PydanticObjectId(current.id))
        if applicant:
            await notify_new_application_on_my_job(
                job=job,
                applicant=applicant,
                application_id=application.id,
            )
    except Exception:
        logger.exception("notify_new_application_on_my_job")
    return _application_to_out(application)


@router.patch(
    "/{job_id}/applications/{application_id}",
    response_model=JobApplicationOut,
)
async def decide_job_application(
    job_id: str,
    application_id: str,
    payload: JobApplicationDecisionIn,
    current: User = Depends(get_current_user),
):
    """صاحب الإعلان: تحديث حالة طلب التقديم — يُرسل إشعاراً للمتقدم عند تغيير الحالة."""
    try:
        job_oid = PydanticObjectId(job_id)
        app_oid = PydanticObjectId(application_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid id")

    job = await JobPosting.get(job_oid)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    if str(job.posted_by) != str(current.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="ليس لديك صلاحية تعديل طلبات هذه الوظيفة",
        )

    application = await JobApplication.get(app_oid)
    if not application or application.job_id != job_oid:
        raise HTTPException(status_code=404, detail="Application not found")

    new_status = payload.status
    if application.status == new_status:
        return _application_to_out(application)

    now = datetime.now(timezone.utc)
    application.status = new_status
    application.updated_at = now
    await application.save()

    try:
        await notify_application_status_to_applicant(
            applicant_id=application.applicant_id,
            job=job,
            application_id=application.id,
            status=new_status.value,
        )
    except Exception:
        logger.exception("notify_application_status_to_applicant")

    return _application_to_out(application)
