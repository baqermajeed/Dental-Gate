const BACKEND_BASE_URL = (
  process.env.BACKEND_BASE_URL || "https://dentalgate.compassaccuracy.com"
).replace(/\/+$/, "");

const jsonHeaders = (accessToken) => {
  const headers = {
    "Content-Type": "application/json",
  };

  if (accessToken) {
    headers.Authorization = `Bearer ${accessToken}`;
  }

  return headers;
};

const parseJsonSafe = async (response) => {
  const text = await response.text();
  if (!text) {
    return null;
  }

  try {
    return JSON.parse(text);
  } catch {
    return { detail: text };
  }
};

const buildApiError = (status, body, fallbackMessage) => {
  const detail =
    body?.detail ||
    body?.message ||
    (typeof body === "string" ? body : null) ||
    fallbackMessage;
  return new Error(`${detail} (status: ${status})`);
};

const withAbsoluteUrl = (urlPath) => {
  if (!urlPath) {
    return "";
  }
  if (urlPath.startsWith("http://") || urlPath.startsWith("https://")) {
    return urlPath;
  }
  return `${BACKEND_BASE_URL}${urlPath.startsWith("/") ? "" : "/"}${urlPath}`;
};

const requestOtp = async (phone) => {
  const response = await fetch(`${BACKEND_BASE_URL}/auth/request-otp`, {
    method: "POST",
    headers: jsonHeaders(),
    body: JSON.stringify({ phone: phone.trim() }),
  });
  const body = await parseJsonSafe(response);
  if (!response.ok) {
    throw buildApiError(response.status, body, "Failed to request OTP");
  }
  return body;
};

const verifyOtp = async (phone, code) => {
  const response = await fetch(`${BACKEND_BASE_URL}/auth/verify-otp`, {
    method: "POST",
    headers: jsonHeaders(),
    body: JSON.stringify({
      phone: phone.trim(),
      code: code.trim(),
    }),
  });

  const body = await parseJsonSafe(response);
  if (!response.ok) {
    throw buildApiError(response.status, body, "Failed to verify OTP");
  }

  return body;
};

const refreshToken = async (refreshTokenValue) => {
  const response = await fetch(`${BACKEND_BASE_URL}/auth/refresh`, {
    method: "POST",
    headers: jsonHeaders(),
    body: JSON.stringify({ refresh_token: refreshTokenValue }),
  });
  const body = await parseJsonSafe(response);
  if (!response.ok) {
    throw buildApiError(response.status, body, "Failed to refresh session");
  }
  return body;
};

const getMe = async (accessToken) => {
  const response = await fetch(`${BACKEND_BASE_URL}/auth/me`, {
    method: "GET",
    headers: jsonHeaders(accessToken),
  });
  const body = await parseJsonSafe(response);
  if (!response.ok) {
    throw buildApiError(response.status, body, "Failed to fetch profile");
  }
  return body;
};

const fetchMyJobs = async (accessToken) => {
  const response = await fetch(`${BACKEND_BASE_URL}/jobs/mine`, {
    method: "GET",
    headers: jsonHeaders(accessToken),
  });
  const body = await parseJsonSafe(response);
  if (!response.ok) {
    throw buildApiError(response.status, body, "Failed to fetch your jobs");
  }
  return Array.isArray(body) ? body : [];
};

const fetchHomeSliders = async () => {
  const response = await fetch(`${BACKEND_BASE_URL}/home-sliders`, {
    method: "GET",
    headers: jsonHeaders(),
  });
  const body = await parseJsonSafe(response);
  if (!response.ok) {
    throw buildApiError(response.status, body, "Failed to fetch sliders");
  }

  const sliders = Array.isArray(body) ? body : [];
  return sliders.map((item) => ({
    ...item,
    image_url_absolute: withAbsoluteUrl(item.image_url),
  }));
};

const uploadSliderImage = async (accessToken, file) => {
  const formData = new FormData();
  const fileBlob = new Blob([file.buffer], { type: file.mimetype });
  formData.append("file", fileBlob, file.originalname);

  const response = await fetch(`${BACKEND_BASE_URL}/home-sliders/upload`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
    body: formData,
  });

  const body = await parseJsonSafe(response);
  if (!response.ok) {
    throw buildApiError(response.status, body, "Failed to upload slider image");
  }
  return body;
};

const createHomeSlider = async (accessToken, payload) => {
  const response = await fetch(`${BACKEND_BASE_URL}/home-sliders`, {
    method: "POST",
    headers: jsonHeaders(accessToken),
    body: JSON.stringify(payload),
  });
  const body = await parseJsonSafe(response);
  if (!response.ok) {
    throw buildApiError(response.status, body, "Failed to publish slider");
  }
  return body;
};

module.exports = {
  BACKEND_BASE_URL,
  requestOtp,
  verifyOtp,
  refreshToken,
  getMe,
  fetchMyJobs,
  fetchHomeSliders,
  uploadSliderImage,
  createHomeSlider,
  withAbsoluteUrl,
};
