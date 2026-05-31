from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.config import get_settings
from app.database import init_db, ping_db
from app.rate_limit import limiter
from app.routers import auth as auth_router
from app.routers import admin_dashboard as admin_dashboard_router
from app.routers import doctor_profile as doctor_profile_router
from app.routers import home_sliders as home_sliders_router
from app.routers import jobs as jobs_router
from app.routers import notifications as notifications_router
from app.routers import saved_doctors as saved_doctors_router
from app.routers import saved_jobs as saved_jobs_router

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    Path(settings.UPLOAD_DIR).mkdir(parents=True, exist_ok=True)
    yield


app = FastAPI(
    title="Dental Gate API",
    description="API لتطبيق جمع أطباء الأسنان — تسجيل ودخول عبر OTP (OTPIQ)",
    version="1.0.0",
    debug=settings.APP_DEBUG,
    lifespan=lifespan,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router.router)
app.include_router(admin_dashboard_router.router)
app.include_router(doctor_profile_router.router)
app.include_router(jobs_router.router)
app.include_router(saved_jobs_router.router)
app.include_router(saved_doctors_router.router)
app.include_router(home_sliders_router.router)
app.include_router(notifications_router.router)

upload_root = Path(settings.UPLOAD_DIR).resolve()
upload_root.mkdir(parents=True, exist_ok=True)
app.mount(
    "/static/uploads",
    StaticFiles(directory=str(upload_root)),
    name="uploads",
)


@app.get("/healthz")
async def healthz():
    return {"status": "ok"}


@app.get("/readyz")
async def readyz():
    if not await ping_db():
        raise HTTPException(status_code=503, detail="Database not ready")
    return {"status": "ok", "database": "up"}
