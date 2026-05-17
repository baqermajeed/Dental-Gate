from datetime import datetime, timezone

from beanie import PydanticObjectId
from fastapi import APIRouter, Depends, HTTPException, Response, status

from app.models.doctor_profile import DoctorProfile
from app.models.saved_doctor import SavedDoctor
from app.models.user import User
from app.schemas.doctor_profile import DoctorSearchItemOut
from app.security import get_current_user
from app.services.otp_service import iraqi_phone_for_display

router = APIRouter(prefix="/saved-doctors", tags=["saved-doctors"])


async def _doctor_to_search_item(user_id: PydanticObjectId) -> DoctorSearchItemOut | None:
    u = await User.get(user_id)
    if not u:
        return None
    dp = await DoctorProfile.find_one(DoctorProfile.user_id == u.id)
    if not dp:
        return None
    title = (dp.professional_title or "").strip() or "طبيب أسنان"
    gov = (dp.governorate or "").strip() or None
    return DoctorSearchItemOut(
        id=str(u.id),
        name=u.name,
        professional_title=title,
        imageUrl=u.imageUrl,
        years_experience=dp.years_experience,
        governorate=gov,
        phone=iraqi_phone_for_display(u.phone),
    )


@router.get("", response_model=list[DoctorSearchItemOut])
async def list_saved_doctors(current: User = Depends(get_current_user)):
    uid = PydanticObjectId(current.id)
    saved = (
        await SavedDoctor.find(SavedDoctor.user_id == uid)
        .sort(-SavedDoctor.created_at)
        .to_list()
    )
    out: list[DoctorSearchItemOut] = []
    for s in saved:
        item = await _doctor_to_search_item(s.doctor_user_id)
        if item:
            out.append(item)
    return out


@router.post(
    "/{doctor_user_id}",
    response_model=DoctorSearchItemOut,
    status_code=status.HTTP_201_CREATED,
)
async def save_doctor(
    doctor_user_id: str, current: User = Depends(get_current_user)
):
    try:
        doctor_oid = PydanticObjectId(doctor_user_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid doctor id")

    if doctor_oid == PydanticObjectId(current.id):
        raise HTTPException(status_code=400, detail="Cannot save your own profile")

    item = await _doctor_to_search_item(doctor_oid)
    if not item:
        raise HTTPException(status_code=404, detail="Doctor not found")

    uid = PydanticObjectId(current.id)
    existing = await SavedDoctor.find_one(
        SavedDoctor.user_id == uid,
        SavedDoctor.doctor_user_id == doctor_oid,
    )
    if not existing:
        now = datetime.now(timezone.utc)
        row = SavedDoctor(
            user_id=uid,
            doctor_user_id=doctor_oid,
            created_at=now,
            updated_at=now,
        )
        await row.insert()
    return item


@router.delete("/{doctor_user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def unsave_doctor(
    doctor_user_id: str, current: User = Depends(get_current_user)
):
    try:
        doctor_oid = PydanticObjectId(doctor_user_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid doctor id")

    uid = PydanticObjectId(current.id)
    existing = await SavedDoctor.find_one(
        SavedDoctor.user_id == uid,
        SavedDoctor.doctor_user_id == doctor_oid,
    )
    if existing:
        await existing.delete()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
