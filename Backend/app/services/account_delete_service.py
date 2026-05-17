"""حذف حساب مستخدم وجميع البيانات المرتبطة به من MongoDB والمجلد المحلي للرفوعات."""

from __future__ import annotations

import logging
import shutil
from pathlib import Path

from beanie import PydanticObjectId
from beanie.operators import In

from app.config import get_settings
from app.models.doctor_profile import DoctorProfile
from app.models.job import JobApplication, JobPosting
from app.models.notification import UserNotification
from app.models.otp import OTPRequest
from app.models.saved_doctor import SavedDoctor
from app.models.saved_job import SavedJob
from app.models.user import User
from app.services.otp_service import normalize_iraqi_phone

logger = logging.getLogger(__name__)


async def delete_user_and_all_related_data(user: User) -> None:
    """حذف نهائي: وظائف، طلبات، محفوظات، إشعارات، بروفايل، OTP، مجلد الرفع، ثم المستخدم."""
    uid = user.id

    posted_jobs = await JobPosting.find(JobPosting.posted_by == uid).to_list()
    job_ids: list[PydanticObjectId] = [j.id for j in posted_jobs]

    if job_ids:
        await JobApplication.find(In(JobApplication.job_id, job_ids)).delete()
        await SavedJob.find(In(SavedJob.job_id, job_ids)).delete()
        await UserNotification.find(In(UserNotification.job_id, job_ids)).delete()

    await JobApplication.find(JobApplication.applicant_id == uid).delete()
    await SavedJob.find(SavedJob.user_id == uid).delete()
    await SavedDoctor.find(SavedDoctor.user_id == uid).delete()
    await SavedDoctor.find(SavedDoctor.doctor_user_id == uid).delete()
    await UserNotification.find(UserNotification.recipient_id == uid).delete()

    await JobPosting.find(JobPosting.posted_by == uid).delete()

    doctor_profile = await DoctorProfile.find_one(DoctorProfile.user_id == uid)
    if doctor_profile:
        await doctor_profile.delete()

    phone_variants: set[str] = {user.phone}
    try:
        n = normalize_iraqi_phone(user.phone)
        phone_variants.add(n)
        if n.startswith("9647") and len(n) > 3:
            phone_variants.add("0" + n[3:])
    except Exception:
        pass
    phones_list = [p for p in phone_variants if p]
    if phones_list:
        await OTPRequest.find(In(OTPRequest.phone, phones_list)).delete()

    upload_root = Path(get_settings().UPLOAD_DIR).resolve()
    user_upload_dir = upload_root / str(uid)
    if user_upload_dir.is_dir():
        try:
            shutil.rmtree(user_upload_dir, ignore_errors=False)
        except OSError as e:
            logger.warning("Could not remove upload dir %s: %s", user_upload_dir, e)

    await user.delete()
