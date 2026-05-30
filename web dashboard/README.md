# Dental Gate Web Dashboard

Web dashboard built with MVC architecture using Node.js, Express, and EJS.

## Features

- Admin login via username/password (`POST /auth/admin-login`)
- Protected dashboard route with access/refresh token session
- Slider publishing flow matching backend:
  - Upload image to `/home-sliders/upload`
  - Publish slider to `/home-sliders` with `job_id` and `image_url`
- App notifications from dashboard:
  - Send announcement to users via `/notifications/app-announcement`
  - Supports both modes: specific `recipient_user_ids` or `send_to_all=true`
  - Uses internal header key `X-Internal-Notifications-Key`
- Slider list loaded from backend `/home-sliders`
- Job selector loaded from backend `/jobs`

## Project Structure

```
src/
  controllers/
  middleware/
  models/
  routes/
  views/
public/
  css/
```

## Run

```bash
npm install
npm run dev
```

Open: `http://localhost:3000`

## Environment Variables

- `BACKEND_BASE_URL` (default: `https://dentalgate.compassaccuracy.com`)
- `SESSION_SECRET`
- `DASHBOARD_NOTIFICATIONS_KEY` (or `INTERNAL_NOTIFICATIONS_KEY`) for app announcements

Backend admin credentials (override in production via `.env` on the API server):

- `DASHBOARD_ADMIN_USERNAME` (default: `admin`)
- `DASHBOARD_ADMIN_PASSWORD` (default: `admin12345`)
