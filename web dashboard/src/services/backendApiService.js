const BACKEND_BASE_URL = (
  process.env.BACKEND_BASE_URL || "https://dentalgate.compassaccuracy.com"
).replace(/\/+$/, "");

const jsonHeaders = ({ accessToken, internalKey, notificationsKey } = {}) => {
  const headers = { "Content-Type": "application/json" };
  if (accessToken) headers.Authorization = `Bearer ${accessToken}`;
  if (internalKey) headers["X-Internal-Dashboard-Key"] = internalKey;
  if (notificationsKey) headers["X-Internal-Notifications-Key"] = notificationsKey;
  return headers;
};

const parseJsonSafe = async (response) => {
  const text = await response.text();
  if (!text) return null;
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
  if (status === 404) {
    return new Error(
      "مسارات admin-dashboard غير موجودة على السيرفر — ارفع آخر نسخة Backend وأعد تشغيل الخدمة. " +
        `(status: ${status})`,
    );
  }
  return new Error(`${detail} (status: ${status})`);
};

const withAbsoluteUrl = (urlPath) => {
  if (!urlPath) return "";
  if (urlPath.startsWith("http://") || urlPath.startsWith("https://")) return urlPath;
  return `${BACKEND_BASE_URL}${urlPath.startsWith("/") ? "" : "/"}${urlPath}`;
};

const requestJson = async (path, options = {}, fallbackMessage = "Request failed") => {
  const response = await fetch(`${BACKEND_BASE_URL}${path}`, options);
  const body = await parseJsonSafe(response);
  if (!response.ok) throw buildApiError(response.status, body, fallbackMessage);
  return body;
};

const withQuery = (path, query = {}) => {
  const params = new URLSearchParams();
  Object.entries(query).forEach(([key, value]) => {
    if (value !== undefined && value !== null && String(value).trim() !== "") {
      params.set(key, String(value));
    }
  });
  const qs = params.toString();
  return qs ? `${path}?${qs}` : path;
};

const adminLogin = async (username, password) =>
  requestJson(
    "/auth/admin-login",
    {
      method: "POST",
      headers: jsonHeaders(),
      body: JSON.stringify({ username: username.trim(), password }),
    },
    "فشل تسجيل الدخول",
  );

const refreshToken = async (refreshTokenValue) =>
  requestJson(
    "/auth/refresh",
    {
      method: "POST",
      headers: jsonHeaders(),
      body: JSON.stringify({ refresh_token: refreshTokenValue }),
    },
    "Failed to refresh session",
  );

const getMe = async (accessToken) =>
  requestJson(
    "/auth/me",
    { method: "GET", headers: jsonHeaders({ accessToken }) },
    "Failed to fetch profile",
  );

const fetchJobPostings = async () => {
  const body = await requestJson(
    "/jobs",
    { method: "GET", headers: jsonHeaders() },
    "Failed to fetch jobs",
  );
  return Array.isArray(body) ? body : [];
};

const fetchHomeSliders = async () => {
  const body = await requestJson(
    "/home-sliders",
    { method: "GET", headers: jsonHeaders() },
    "Failed to fetch sliders",
  );
  const sliders = Array.isArray(body) ? body : [];
  return sliders.map((item) => ({
    ...item,
    image_url_absolute: withAbsoluteUrl(item.image_url),
  }));
};

const uploadSliderImage = async (accessToken, file, internalKey) => {
  const formData = new FormData();
  const fileBlob = new Blob([file.buffer], { type: file.mimetype });
  formData.append("file", fileBlob, file.originalname);
  const headers = {};
  if (accessToken) headers.Authorization = `Bearer ${accessToken}`;
  if (internalKey) headers["X-Internal-Dashboard-Key"] = internalKey;
  return requestJson(
    "/home-sliders/upload",
    { method: "POST", headers, body: formData },
    "Failed to upload slider image",
  );
};

const createHomeSlider = async (accessToken, payload, internalKey) =>
  requestJson(
    "/home-sliders",
    {
      method: "POST",
      headers: jsonHeaders({ accessToken, internalKey }),
      body: JSON.stringify(payload),
    },
    "Failed to publish slider",
  );

const deleteHomeSlider = async (sliderId, accessToken, internalKey) => {
  await requestJson(
    `/home-sliders/${sliderId}`,
    { method: "DELETE", headers: jsonHeaders({ accessToken, internalKey }) },
    "Failed to delete slider",
  );
  return true;
};

const createAppAnnouncement = async (payload, notificationsKey) =>
  requestJson(
    "/notifications/app-announcement",
    {
      method: "POST",
      headers: jsonHeaders({ notificationsKey }),
      body: JSON.stringify(payload),
    },
    "Failed to publish app announcement",
  );

const checkAdminApiHealth = async () =>
  requestJson(
    "/admin-dashboard/health",
    { method: "GET", headers: jsonHeaders() },
    "Admin dashboard API is not available on this backend",
  );

const fetchAdminOverview = async (accessToken) =>
  requestJson(
    "/admin-dashboard/overview",
    { method: "GET", headers: jsonHeaders({ accessToken }) },
    "Failed to fetch dashboard overview",
  );

const fetchAdminUsers = async (accessToken, query = {}) =>
  requestJson(
    withQuery("/admin-dashboard/users", query),
    { method: "GET", headers: jsonHeaders({ accessToken }) },
    "Failed to fetch users",
  );

const fetchVerificationQueue = async (accessToken, statusFilter = "pending") =>
  requestJson(
    withQuery("/admin-dashboard/verifications", { status_filter: statusFilter }),
    { method: "GET", headers: jsonHeaders({ accessToken }) },
    "Failed to fetch verification queue",
  );

const reviewPracticeLicense = async (accessToken, userId, decision, rejectionReason = "") =>
  requestJson(
    `/admin-dashboard/verifications/practice-license/${userId}`,
    {
      method: "PATCH",
      headers: jsonHeaders({ accessToken }),
      body: JSON.stringify({
        decision,
        rejection_reason: rejectionReason || null,
      }),
    },
    "Failed to review practice license",
  );

const reviewAccreditedCourse = async (
  accessToken,
  userId,
  courseId,
  decision,
  rejectionReason = "",
) =>
  requestJson(
    `/admin-dashboard/verifications/accredited-courses/${userId}/${courseId}`,
    {
      method: "PATCH",
      headers: jsonHeaders({ accessToken }),
      body: JSON.stringify({
        decision,
        rejection_reason: rejectionReason || null,
      }),
    },
    "Failed to review accredited course",
  );

const fetchAdminJobs = async (accessToken, query = {}) =>
  requestJson(
    withQuery("/admin-dashboard/jobs", query),
    { method: "GET", headers: jsonHeaders({ accessToken }) },
    "Failed to fetch jobs for dashboard",
  );

const updateAdminJobStatus = async (accessToken, jobId, statusValue) =>
  requestJson(
    `/admin-dashboard/jobs/${jobId}/status`,
    {
      method: "PATCH",
      headers: jsonHeaders({ accessToken }),
      body: JSON.stringify({ status: statusValue }),
    },
    "Failed to update job status",
  );

const deleteAdminJob = async (accessToken, jobId) => {
  await requestJson(
    `/admin-dashboard/jobs/${jobId}`,
    { method: "DELETE", headers: jsonHeaders({ accessToken }) },
    "Failed to delete job",
  );
  return true;
};

const fetchAnnouncementLogs = async (accessToken, limit = 60) =>
  requestJson(
    withQuery("/admin-dashboard/notifications/announcements", { limit }),
    { method: "GET", headers: jsonHeaders({ accessToken }) },
    "Failed to fetch announcement logs",
  );

module.exports = {
  BACKEND_BASE_URL,
  adminLogin,
  refreshToken,
  getMe,
  fetchJobPostings,
  fetchHomeSliders,
  uploadSliderImage,
  createHomeSlider,
  deleteHomeSlider,
  createAppAnnouncement,
  checkAdminApiHealth,
  fetchAdminOverview,
  fetchAdminUsers,
  fetchVerificationQueue,
  reviewPracticeLicense,
  reviewAccreditedCourse,
  fetchAdminJobs,
  updateAdminJobStatus,
  deleteAdminJob,
  fetchAnnouncementLogs,
  withAbsoluteUrl,
};
