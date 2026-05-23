from datetime import datetime, timezone

from beanie import PydanticObjectId
from fastapi import APIRouter, Depends, HTTPException, Response, status

from app.models.job import JobPosting
from app.models.saved_job import SavedJob
from app.models.user import User
from app.schemas.jobs import JobPostingOut
from app.security import get_current_user
from app.utils.datetime_utils import ensure_utc

router = APIRouter(prefix="/saved-jobs", tags=["saved-jobs"])


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


@router.get("", response_model=list[JobPostingOut])
async def list_saved_jobs(current: User = Depends(get_current_user)):
    now = datetime.now(timezone.utc)
    uid = PydanticObjectId(current.id)
    saved = (
        await SavedJob.find(SavedJob.user_id == uid).sort(-SavedJob.created_at).to_list()
    )
    out: list[JobPostingOut] = []
    for s in saved:
        job = await JobPosting.get(s.job_id)
        deadline = ensure_utc(job.application_deadline) if job else None
        if job and (deadline is None or deadline >= now):
            out.append(_job_to_out(job))
    return out


@router.post("/{job_id}", response_model=JobPostingOut, status_code=status.HTTP_201_CREATED)
async def save_job(job_id: str, current: User = Depends(get_current_user)):
    try:
        oid = PydanticObjectId(job_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid job id")

    job = await JobPosting.get(oid)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    uid = PydanticObjectId(current.id)
    existing = await SavedJob.find_one(SavedJob.user_id == uid, SavedJob.job_id == oid)
    if not existing:
        now = datetime.now(timezone.utc)
        saved = SavedJob(user_id=uid, job_id=oid, created_at=now, updated_at=now)
        await saved.insert()
    return _job_to_out(job)


@router.delete("/{job_id}", status_code=status.HTTP_204_NO_CONTENT)
async def unsave_job(job_id: str, current: User = Depends(get_current_user)):
    try:
        oid = PydanticObjectId(job_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid job id")

    uid = PydanticObjectId(current.id)
    existing = await SavedJob.find_one(SavedJob.user_id == uid, SavedJob.job_id == oid)
    if existing:
        await existing.delete()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
