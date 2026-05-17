# Dental Gate Web Dashboard

Web dashboard built with MVC architecture using Node.js, Express, and EJS.

## Features

- OTP login connected to backend API (`/auth/request-otp`, `/auth/verify-otp`)
- Protected dashboard route with access/refresh token session
- Slider publishing flow matching backend:
  - Upload image to `/home-sliders/upload`
  - Publish slider to `/home-sliders` with `job_id` and `image_url`
- Slider list loaded from backend `/home-sliders`
- Job selector loaded from backend `/jobs/mine`

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
