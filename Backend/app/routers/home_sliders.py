import uuid
from datetime import datetime, timezone
from pathlib import Path

from beanie import PydanticObjectId
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

from app.config import get_settings
from app.models.home_slider import HomeSlider
from app.models.job import JobPosting
from app.models.user import User
from app.schemas.home_slider import HomeSliderCreateIn, HomeSliderOut
from app.security import get_current_user

router = APIRouter(prefix="/home-sliders", tags=["home-sliders"])
settings = get_settings()

_ALLOWED_EXT = {".jpg", ".jpeg", ".png", ".webp"}
_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}


def _slider_to_out(item: HomeSlider) -> HomeSliderOut:
    return HomeSliderOut(
        id=str(item.id),
        job_id=str(item.job_id),
        image_url=item.image_url,
        created_at=item.created_at,
        updated_at=item.updated_at,
    )


@router.get("", response_model=list[HomeSliderOut])
async def list_home_sliders():
    items = await HomeSlider.find_all().sort(-HomeSlider.created_at).to_list()
    return [_slider_to_out(i) for i in items]


@router.post("", response_model=HomeSliderOut, status_code=status.HTTP_201_CREATED)
async def create_home_slider(
    payload: HomeSliderCreateIn,
    current: User = Depends(get_current_user),
):
    _ = current
    try:
        job_oid = PydanticObjectId(payload.job_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid job id")

    job = await JobPosting.get(job_oid)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    now = datetime.now(timezone.utc)
    item = HomeSlider(
        job_id=job_oid,
        image_url=payload.image_url.strip(),
        created_at=now,
        updated_at=now,
    )
    await item.insert()
    return _slider_to_out(item)


@router.post("/upload", response_model=dict)
async def upload_slider_image(
    current: User = Depends(get_current_user),
    file: UploadFile = File(..., description="صورة السلايدر"),
):
    ct = (file.content_type or "").split(";")[0].strip().lower()
    if ct and ct not in _CONTENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="نوع الملف غير مدعوم (استخدم jpg أو png أو webp)",
        )

    raw_name = file.filename or "upload.bin"
    suffix = Path(raw_name).suffix.lower()
    if suffix not in _ALLOWED_EXT:
        raise HTTPException(status_code=400, detail="امتداد الملف غير مدعوم")

    content = await file.read()
    max_b = settings.UPLOAD_MAX_BYTES
    if len(content) > max_b:
        raise HTTPException(
            status_code=400,
            detail=f"حجم الملف يتجاوز {max_b // (1024 * 1024)} ميجابايت",
        )

    safe = f"{uuid.uuid4().hex}{suffix}"
    user_dir = Path(settings.UPLOAD_DIR) / "home-sliders" / str(current.id)
    user_dir.mkdir(parents=True, exist_ok=True)
    dest = user_dir / safe
    dest.write_bytes(content)

    url = f"/static/uploads/home-sliders/{current.id}/{safe}"
    return {"url": url, "filename": safe}
