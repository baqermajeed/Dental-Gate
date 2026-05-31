# نشر الباكند على السيرفر (حل خطأ 404 في لوحة التحكم)

## المشكلة

لوحة التحكم تستدعي مسارات مثل:

- `GET /admin-dashboard/overview`
- `GET /admin-dashboard/verifications`

إذا رجع السيرفر **404 Not Found** فالنسخة المنشورة **قديمة** ولا تحتوي كود `admin_dashboard`.

## التحقق السريع

```bash
curl -s https://dentalgate.compassaccuracy.com/healthz
curl -s https://dentalgate.compassaccuracy.com/admin-dashboard/health
```

| النتيجة | المعنى |
|---------|--------|
| `/healthz` → 200 و `/admin-dashboard/health` → 404 | الباكند يعمل لكن **لم يُرفع** تحديث لوحة التحكم |
| `/admin-dashboard/health` → 200 | API جاهز؛ إذا بقيت 401 على overview فالمشكلة في تسجيل الدخول/صلاحيات admin |

## خطوات النشر على VPS

```bash
# 1) اتصل بالسيرفر
ssh user@your-server

# 2) ادخل مجلد المشروع
cd /path/to/Dental-Gate/Backend

# 3) اسحب آخر كود
git pull origin main

# 4) فعّل البيئة الافتراضية (أو أنشئها)
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 5) تأكد من ملف .env على السيرفر
# INTERNAL_DASHBOARD_KEY=...
# INTERNAL_NOTIFICATIONS_KEY=...
# DASHBOARD_ADMIN_USERNAME=admin
# DASHBOARD_ADMIN_PASSWORD=...
# (نفس القيم في web dashboard/.env)

# 6) أعد تشغيل الخدمة
sudo systemctl restart dentalgate-api
# أو: pm2 restart dentalgate
# أو: kill + uvicorn app.main:app --host 0.0.0.0 --port 8000

# 7) تحقق
curl -s https://dentalgate.compassaccuracy.com/admin-dashboard/health
```

## ملفات مهمة في التحديث

- `app/routers/admin_dashboard.py`
- `app/schemas/admin_dashboard.py`
- `app/security_dashboard.py` (يحل تعارض import مع `app/security.py`)
- `app/main.py` (تسجيل router + `/admin-dashboard/health`)
- `app/security.py` (`require_admin`)

## بعد النشر

1. أعد تشغيل **web dashboard** إن لزم (Node).
2. سجّل دخول admin من `/login`.
3. صفحة Overview و Verifications يجب أن تعرض البيانات بدون 404.

## استكشاف الأخطاء

| الخطأ | الحل |
|-------|------|
| 404 على `/admin-dashboard/*` | `git pull` + إعادة تشغيل uvicorn |
| 401 Unauthorized | بيانات admin خاطئة أو JWT منتهي — سجّل خروج/دخول |
| 503 Database | MongoDB غير متصل — راجع `MONGODB_URI` |
| ImportError `security.dashboard` | تأكد وجود `app/security_dashboard.py` وتحديث `home_sliders.py` |
