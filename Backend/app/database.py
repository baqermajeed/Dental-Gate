from beanie import init_beanie
from motor.motor_asyncio import AsyncIOMotorClient

from app.config import get_settings

settings = get_settings()

_mongo_client: AsyncIOMotorClient | None = None


async def init_db() -> None:
    global _mongo_client
    _mongo_client = AsyncIOMotorClient(settings.MONGODB_URI)
    db_name = settings.MONGODB_URI.rsplit("/", 1)[-1].split("?")[0]
    if not db_name:
        db_name = "dental_gate_db"

    from app.models import (
        HomeSlider,
        JobApplication,
        JobPosting,
        OTPRequest,
        SavedDoctor,
        SavedJob,
        User,
        UserNotification,
    )
    from app.models.doctor_profile import DoctorProfile
    from app.models.doctor_peer_rating import DoctorPeerRating

    await init_beanie(
        database=_mongo_client[db_name],
        document_models=[
            User,
            OTPRequest,
            DoctorProfile,
            DoctorPeerRating,
            JobPosting,
            JobApplication,
            SavedJob,
            SavedDoctor,
            HomeSlider,
            UserNotification,
        ],
    )


async def ping_db() -> bool:
    if not _mongo_client:
        return False
    try:
        await _mongo_client.admin.command("ping")
        return True
    except Exception:
        return False
