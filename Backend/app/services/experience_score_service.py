"""حساب وتخزين نقاط الخبرة للطبيب داخل الباكند."""

from datetime import datetime, timezone

from beanie import PydanticObjectId

from app.models.doctor_peer_rating import DoctorPeerRating
from app.models.doctor_profile import (
    ACCREDITED_COURSE_POINTS_MAX,
    DegreeType,
    DoctorProfile,
    ExperienceScoreSnapshot,
    ExperienceTaskScore,
    ExperienceTaskVerification,
    ExperienceTier,
    PracticeLicenseStatus,
)

_PEER_RATINGS_INCOMING_MAX = 5
_PEER_RATINGS_OUTGOING_MAX = 2
_PEER_RATINGS_INCOMING_REQUIRED = 10
_PEER_RATINGS_OUTGOING_REQUIRED = 5
_PRACTICE_LICENSE_MAX = 8
_EXPERIENCE_TOTAL_CAP = 70


def _peer_ratings_incoming_points(received_count: int) -> int:
    if received_count <= 0:
        return 0
    scaled = (received_count * _PEER_RATINGS_INCOMING_MAX) // _PEER_RATINGS_INCOMING_REQUIRED
    return max(0, min(_PEER_RATINGS_INCOMING_MAX, scaled))


def _peer_ratings_outgoing_points(given_count: int) -> int:
    if given_count <= 0:
        return 0
    scaled = (given_count * _PEER_RATINGS_OUTGOING_MAX) // _PEER_RATINGS_OUTGOING_REQUIRED
    return max(0, min(_PEER_RATINGS_OUTGOING_MAX, scaled))


def _highest_degree_points(dp: DoctorProfile) -> int:
    best = 0
    for item in dp.education:
        degree = item.degree_type
        if degree == DegreeType.DOCTORATE:
            pts = 12
        elif degree == DegreeType.MASTER:
            pts = 8
        elif degree == DegreeType.BACHELOR:
            pts = 5
        elif degree == DegreeType.DIPLOMA:
            pts = 3
        else:
            pts = 0
        if pts > best:
            best = pts
    return best


def _years_experience_points(years: int | None) -> int:
    if years is None or years < 1:
        return 0
    if years >= 10:
        return 8
    if years >= 5:
        return 6
    if years >= 3:
        return 4
    return 2


def _courses_points_earned(dp: DoctorProfile) -> int:
    total = sum(
        c.points_awarded
        for c in dp.accredited_courses
        if c.status == PracticeLicenseStatus.APPROVED
    )
    return min(total, ACCREDITED_COURSE_POINTS_MAX)


def _tier_for_points(points: int) -> ExperienceTier:
    if points >= 55:
        return ExperienceTier.DIAMOND
    if points >= 40:
        return ExperienceTier.PLATINUM
    if points >= 20:
        return ExperienceTier.GOLD
    return ExperienceTier.SILVER


def compute_snapshot(
    dp: DoctorProfile,
    *,
    peer_ratings_received: int,
    peer_ratings_given: int,
) -> ExperienceScoreSnapshot:
    has_bio = bool((dp.bio or "").strip())
    has_education = bool(dp.education)
    has_experiences = bool(dp.experiences)
    has_skills = bool(dp.skill_ids)
    has_languages = bool(dp.languages)
    gallery_count = len(dp.gallery)
    practice_license = dp.practice_license

    bio_pts = 1 if has_bio else 0
    edu_info_pts = 2 if has_education else 0
    degree_pts = _highest_degree_points(dp)
    exp_pts = 2 if has_experiences else 0
    skill_pts = 1 if has_skills else 0
    lang_pts = 1 if has_languages else 0
    gallery3_pts = min(3, gallery_count)
    gallery15_pts = 5 if gallery_count >= 15 else 0
    years_pts = _years_experience_points(dp.years_experience)

    practice_license_pts = 0
    pl_verification = ExperienceTaskVerification.NONE
    pl_opens_dialog = True
    if practice_license is not None:
        if practice_license.status == PracticeLicenseStatus.APPROVED:
            practice_license_pts = _PRACTICE_LICENSE_MAX
            pl_verification = ExperienceTaskVerification.APPROVED
            pl_opens_dialog = False
        elif practice_license.status == PracticeLicenseStatus.PENDING:
            pl_verification = ExperienceTaskVerification.PENDING
            pl_opens_dialog = False
        elif practice_license.status == PracticeLicenseStatus.REJECTED:
            pl_verification = ExperienceTaskVerification.REJECTED
            pl_opens_dialog = True

    courses_pts = _courses_points_earned(dp)
    courses_pending = sum(
        1 for c in dp.accredited_courses if c.status == PracticeLicenseStatus.PENDING
    )
    courses_rejected = sum(
        1 for c in dp.accredited_courses if c.status == PracticeLicenseStatus.REJECTED
    )
    courses_verification = ExperienceTaskVerification.NONE
    courses_opens_dialog = courses_pts < ACCREDITED_COURSE_POINTS_MAX
    if courses_pending > 0:
        courses_verification = ExperienceTaskVerification.PENDING
    elif courses_rejected > 0 and courses_pts < ACCREDITED_COURSE_POINTS_MAX:
        courses_verification = ExperienceTaskVerification.REJECTED
    elif courses_pts >= ACCREDITED_COURSE_POINTS_MAX:
        courses_verification = ExperienceTaskVerification.APPROVED
        courses_opens_dialog = False

    peer_in_pts = _peer_ratings_incoming_points(peer_ratings_received)
    peer_out_pts = _peer_ratings_outgoing_points(peer_ratings_given)
    platform_pts = 0

    tasks = [
        ExperienceTaskScore(id="bio", title="النبذة المهنية", earned=bio_pts, max=1),
        ExperienceTaskScore(
            id="education_info",
            title="بيانات التعليم",
            earned=edu_info_pts,
            max=2,
        ),
        ExperienceTaskScore(id="degree", title="أعلى مؤهل أكاديمي", earned=degree_pts, max=12),
        ExperienceTaskScore(id="work", title="الخبرات العملية", earned=exp_pts, max=2),
        ExperienceTaskScore(id="skills", title="المهارات", earned=skill_pts, max=1),
        ExperienceTaskScore(id="languages", title="اللغات", earned=lang_pts, max=1),
        ExperienceTaskScore(id="gallery3", title="معرض الحالات (3 حالات)", earned=gallery3_pts, max=3),
        ExperienceTaskScore(id="gallery15", title="معرض الحالات (15 حالة)", earned=gallery15_pts, max=5),
        ExperienceTaskScore(
            id="practice_license",
            title="شهادة ممارسة المهنة",
            earned=practice_license_pts,
            max=_PRACTICE_LICENSE_MAX,
            verification=pl_verification,
            opens_submit_dialog=pl_opens_dialog,
        ),
        ExperienceTaskScore(id="years", title="سنوات الخبرة", earned=years_pts, max=8),
        ExperienceTaskScore(
            id="courses",
            title="دورات معتمدة",
            earned=courses_pts,
            max=ACCREDITED_COURSE_POINTS_MAX,
            verification=courses_verification,
            opens_submit_dialog=courses_opens_dialog,
        ),
        ExperienceTaskScore(
            id="peer_in",
            title="تقييم الزملاء (وارد)",
            earned=peer_in_pts,
            max=_PEER_RATINGS_INCOMING_MAX,
        ),
        ExperienceTaskScore(
            id="peer_out",
            title="تقييم الزملاء (صادر)",
            earned=peer_out_pts,
            max=_PEER_RATINGS_OUTGOING_MAX,
        ),
        ExperienceTaskScore(
            id="platform",
            title="نشاط المنصة",
            earned=platform_pts,
            max=10,
            coming_soon=True,
        ),
    ]
    total_raw = sum(t.earned for t in tasks)
    total_max = sum(t.max for t in tasks)
    total_earned = max(0, min(total_max, total_raw))
    total_earned = min(total_earned, _EXPERIENCE_TOTAL_CAP)

    return ExperienceScoreSnapshot(
        total_earned=total_earned,
        total_max=total_max,
        tier=_tier_for_points(total_earned),
        tasks=tasks,
        peer_ratings_received=peer_ratings_received,
        peer_ratings_given=peer_ratings_given,
        computed_at=datetime.now(timezone.utc),
    )


async def recompute_and_persist_for_user(user_id: PydanticObjectId) -> DoctorProfile:
    """يعيد حساب السكور لطبيب ويخزّنه داخل وثيقة DoctorProfile."""
    dp = await DoctorProfile.find_one(DoctorProfile.user_id == user_id)
    if dp is None:
        dp = DoctorProfile(user_id=user_id)
        await dp.insert()

    peer_received = await DoctorPeerRating.find(
        DoctorPeerRating.target_user_id == user_id
    ).count()
    peer_given = await DoctorPeerRating.find(
        DoctorPeerRating.rater_user_id == user_id
    ).count()

    dp.experience_score = compute_snapshot(
        dp,
        peer_ratings_received=peer_received,
        peer_ratings_given=peer_given,
    )
    dp.experience_score_updated_at = datetime.now(timezone.utc)
    await dp.save()
    return dp

