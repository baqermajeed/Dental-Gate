@echo off
REM تشغيل Dental Gate API — من مجلد backend
cd /d "%~dp0"

if exist ".venv\Scripts\activate.bat" (
  call ".venv\Scripts\activate.bat"
)

echo Starting uvicorn: http://127.0.0.1:8000  ^|  docs: http://127.0.0.1:8000/docs
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
pause
