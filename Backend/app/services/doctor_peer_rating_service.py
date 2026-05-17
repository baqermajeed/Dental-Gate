"""تقييمات الزملاء — إرسال وعرض فوري."""

from datetime import datetime, timezone

from beanie import PydanticObjectId
from fastapi import HTTPException, status
from pymongo.errors import DuplicateKeyError

from app.models.doctor_peer_rating import DoctorPeerRating
from app.models.user import User
from app.schemas.doctor_peer_rating import (
    DoctorPeerRatingOut,
    DoctorPeerRatingSubmitIn,
    DoctorPeerRatingsListOut,
)
from app.services import experience_score_service as experience_score_svc


def _to_out(r: DoctorPeerRating) -> DoctorPeerRatingOut:
    return DoctorPeerRatingOut(
        id=str(r.id),
        stars=r.stars,
        comment=r.comment or "",
        rater_user_id=str(r.rater_user_id),
        rater_name=r.rater_name,
        rater_image_url=r.rater_image_url,
        created_at=r.created_at,
    )


async def list_ratings_for_doctor(
    target_user_id: PydanticObjectId,
    current_user: User | None = None,
) -> DoctorPeerRatingsListOut:
    rows = (
        await DoctorPeerRating.find(
            {"target_user_id": target_user_id},
        )
        .sort([("created_at", -1)])
        .to_list()
    )
    ratings = [_to_out(r) for r in rows]
    avg = None
    if ratings:
        avg = round(sum(r.stars for r in ratings) / len(ratings), 1)

    current_has = False
    current_rating = None
    ratings_given_count = 0
    if current_user is not None:
        mine = await DoctorPeerRating.find_one(
            {
                "target_user_id": target_user_id,
                "rater_user_id": current_user.id,
            }
        )
        if mine:
            current_has = True
            current_rating = _to_out(mine)
        ratings_given_count = await DoctorPeerRating.find(
            DoctorPeerRating.rater_user_id == current_user.id
        ).count()

    return DoctorPeerRatingsListOut(
        ratings=ratings,
        average_stars=avg,
        total_count=len(ratings),
        current_user_has_rated=current_has,
        current_user_rating=current_rating,
        ratings_given_count=ratings_given_count,
    )


async def submit_peer_rating(
    rater: User,
    target_user_id: PydanticObjectId,
    payload: DoctorPeerRatingSubmitIn,
) -> DoctorPeerRatingOut:
    if rater.id == target_user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="لا يمكنك تقييم نفسك",
        )

    target = await User.get(target_user_id)
    if not target:
        raise HTTPException(status_code=404, detail="الطبيب غير موجود")

    existing = await DoctorPeerRating.find_one(
        {
            "target_user_id": target_user_id,
            "rater_user_id": rater.id,
        }
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="لقد قيّمت هذا الطبيب مسبقاً",
        )

    row = DoctorPeerRating(
        target_user_id=target_user_id,
        rater_user_id=rater.id,
        stars=payload.stars,
        comment=payload.comment or "",
        rater_name=rater.name,
        rater_image_url=rater.imageUrl,
        created_at=datetime.now(timezone.utc),
    )
    try:
        await row.insert()
    except DuplicateKeyError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="لقد قيّمت هذا الطبيب مسبقاً",
        )

    # تحديث نقاط الخبرة للطرفين بعد تسجيل التقييم.
    await experience_score_svc.recompute_and_persist_for_user(target_user_id)
    await experience_score_svc.recompute_and_persist_for_user(rater.id)

    return _to_out(row)
