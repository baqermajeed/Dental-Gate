# تشغيل Dental Gate API — نفّذ من مجلد backend
Set-Location $PSScriptRoot

if (Test-Path ".\.venv\Scripts\Activate.ps1") {
    & ".\.venv\Scripts\Activate.ps1"
}

Write-Host "Starting: http://127.0.0.1:8000  |  docs: http://127.0.0.1:8000/docs" -ForegroundColor Cyan
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
