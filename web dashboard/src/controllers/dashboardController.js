const backendApi = require("../services/backendApiService");
const { DASHBOARD_INTERNAL_KEY, DASHBOARD_NOTIFICATIONS_KEY } = require("../config/adminConfig");

const navItems = [
  { href: "/dashboard", key: "overview", label: "Overview" },
  { href: "/dashboard/users", key: "users", label: "Users" },
  { href: "/dashboard/verifications", key: "verifications", label: "Verifications" },
  { href: "/dashboard/jobs", key: "jobs", label: "Jobs" },
  { href: "/dashboard/notifications", key: "notifications", label: "Notifications" },
  { href: "/dashboard/sliders", key: "sliders", label: "Sliders" },
];

const setFlash = (req, type, message) => {
  req.session.flash = { type, message };
};

const setApiErrorFlash = (req, res, error) => {
  const isAdminApiMissing =
    res.locals.adminApiReady === false || String(error.message).includes("status: 404");
  if (isAdminApiMissing) return;
  setFlash(req, "error", error.message);
};

const resolveAuth = (req) => {
  const accessToken = req.session.tokens?.accessToken || "";
  if (accessToken) return { accessToken, internalKey: null };
  if (DASHBOARD_INTERNAL_KEY) return { accessToken: null, internalKey: DASHBOARD_INTERNAL_KEY };
  throw new Error("انتهت جلسة المدير. سجّل الدخول مجدداً.");
};

const withAuthRetry = async (req, action) => {
  const auth = resolveAuth(req);
  try {
    return await action(auth);
  } catch (error) {
    if (!String(error.message).includes("status: 401") || !auth.accessToken) throw error;
    const refreshValue = req.session.tokens?.refreshToken;
    if (!refreshValue) throw new Error("انتهت الجلسة. سجّل الدخول مرة أخرى.");
    const refreshed = await backendApi.refreshToken(refreshValue);
    req.session.tokens = {
      accessToken: refreshed.access_token,
      refreshToken: refreshed.refresh_token,
    };
    return action({ accessToken: req.session.tokens.accessToken, internalKey: null });
  }
};

const renderDashboardPage = (res, view, locals = {}) =>
  res.render(view, {
    title: "Dental Gate Dashboard",
    backendBaseUrl: backendApi.BACKEND_BASE_URL,
    navItems,
    activePage: "overview",
    ...locals,
  });

const toQueryString = (input) => {
  const params = new URLSearchParams();
  Object.entries(input || {}).forEach(([key, value]) => {
    if (value !== undefined && value !== null && String(value) !== "") {
      params.set(key, String(value));
    }
  });
  return params.toString();
};

const showOverview = async (req, res) => {
  try {
    const data = await withAuthRetry(req, ({ accessToken }) => backendApi.fetchAdminOverview(accessToken));
    return renderDashboardPage(res, "dashboard/overview", {
      activePage: "overview",
      data,
    });
  } catch (error) {
    setApiErrorFlash(req, res, error);
    return renderDashboardPage(res, "dashboard/overview", {
      activePage: "overview",
      data: {
        generated_at: null,
        kpis: {},
        jobs_by_status: {},
        applications_by_status: {},
        users_by_governorate: {},
        users_by_professional_title: {},
        users_by_tier: {},
      },
    });
  }
};

const showUsers = async (req, res) => {
  const filters = {
    q: req.query.q || "",
    governorate: req.query.governorate || "",
    professional_title: req.query.professional_title || "",
    limit: req.query.limit || "25",
    offset: req.query.offset || "0",
  };
  try {
    const result = await withAuthRetry(req, ({ accessToken }) => backendApi.fetchAdminUsers(accessToken, filters));
    return renderDashboardPage(res, "dashboard/users", {
      activePage: "users",
      filters,
      result,
    });
  } catch (error) {
    setApiErrorFlash(req, res, error);
    return renderDashboardPage(res, "dashboard/users", {
      activePage: "users",
      filters,
      result: { items: [], total: 0, limit: 25, offset: 0 },
    });
  }
};

const showVerifications = async (req, res) => {
  const statusFilter = req.query.status_filter || "pending";
  try {
    const queue = await withAuthRetry(req, ({ accessToken }) =>
      backendApi.fetchVerificationQueue(accessToken, statusFilter),
    );
    return renderDashboardPage(res, "dashboard/verifications", {
      activePage: "verifications",
      statusFilter,
      queue,
    });
  } catch (error) {
    setApiErrorFlash(req, res, error);
    return renderDashboardPage(res, "dashboard/verifications", {
      activePage: "verifications",
      statusFilter,
      queue: { practice_licenses: [], accredited_courses: [] },
    });
  }
};

const decidePracticeLicense = async (req, res) => {
  const decision = String(req.body.decision || "").trim();
  const rejectionReason = String(req.body.rejectionReason || "").trim();
  try {
    await withAuthRetry(req, ({ accessToken }) =>
      backendApi.reviewPracticeLicense(accessToken, req.params.userId, decision, rejectionReason),
    );
    setFlash(req, "success", "Practice license updated.");
  } catch (error) {
    setApiErrorFlash(req, res, error);
  }
  return res.redirect(`/dashboard/verifications?status_filter=${encodeURIComponent(req.query.status_filter || "pending")}`);
};

const decideAccreditedCourse = async (req, res) => {
  const decision = String(req.body.decision || "").trim();
  const rejectionReason = String(req.body.rejectionReason || "").trim();
  try {
    await withAuthRetry(req, ({ accessToken }) =>
      backendApi.reviewAccreditedCourse(
        accessToken,
        req.params.userId,
        req.params.courseId,
        decision,
        rejectionReason,
      ),
    );
    setFlash(req, "success", "Accredited course updated.");
  } catch (error) {
    setApiErrorFlash(req, res, error);
  }
  return res.redirect(`/dashboard/verifications?status_filter=${encodeURIComponent(req.query.status_filter || "pending")}`);
};

const showJobs = async (req, res) => {
  const filters = {
    q: req.query.q || "",
    status_filter: req.query.status_filter || "",
    limit: req.query.limit || "25",
    offset: req.query.offset || "0",
  };
  try {
    const result = await withAuthRetry(req, ({ accessToken }) => backendApi.fetchAdminJobs(accessToken, filters));
    const queryString = toQueryString(filters);
    return renderDashboardPage(res, "dashboard/jobs", {
      activePage: "jobs",
      filters,
      queryString,
      result,
    });
  } catch (error) {
    setApiErrorFlash(req, res, error);
    return renderDashboardPage(res, "dashboard/jobs", {
      activePage: "jobs",
      filters,
      queryString: toQueryString(filters),
      result: { items: [], total: 0, limit: 25, offset: 0 },
    });
  }
};

const updateJobStatus = async (req, res) => {
  const statusValue = String(req.body.status || "").trim();
  try {
    await withAuthRetry(req, ({ accessToken }) =>
      backendApi.updateAdminJobStatus(accessToken, req.params.jobId, statusValue),
    );
    setFlash(req, "success", "Job status updated.");
  } catch (error) {
    setApiErrorFlash(req, res, error);
  }
  return res.redirect(`/dashboard/jobs?${new URLSearchParams(req.query).toString()}`);
};

const deleteJob = async (req, res) => {
  try {
    await withAuthRetry(req, ({ accessToken }) => backendApi.deleteAdminJob(accessToken, req.params.jobId));
    setFlash(req, "success", "Job deleted successfully.");
  } catch (error) {
    setApiErrorFlash(req, res, error);
  }
  return res.redirect(`/dashboard/jobs?${new URLSearchParams(req.query).toString()}`);
};

const showNotifications = async (req, res) => {
  try {
    const logs = await withAuthRetry(req, ({ accessToken }) =>
      backendApi.fetchAnnouncementLogs(accessToken, 80),
    );
    return renderDashboardPage(res, "dashboard/notifications", {
      activePage: "notifications",
      logs,
    });
  } catch (error) {
    setApiErrorFlash(req, res, error);
    return renderDashboardPage(res, "dashboard/notifications", {
      activePage: "notifications",
      logs: [],
    });
  }
};

const sendAppAnnouncement = async (req, res) => {
  const title = String(req.body.title || "").trim();
  const body = String(req.body.body || "").trim();
  const shouldSendToAll = req.body.sendToAll === "on";
  const recipientUserIds = String(req.body.recipientUserIds || "");

  if (!title || !body) {
    setFlash(req, "error", "Title and body are required.");
    return res.redirect("/dashboard/notifications");
  }

  const recipients = shouldSendToAll
    ? []
    : [...new Set(recipientUserIds.split(/[\n,]+/).map((x) => x.trim()).filter(Boolean))];
  if (!shouldSendToAll && recipients.length === 0) {
    setFlash(req, "error", "Please add at least one recipient user id.");
    return res.redirect("/dashboard/notifications");
  }
  if (!DASHBOARD_NOTIFICATIONS_KEY) {
    setFlash(req, "error", "Missing DASHBOARD_NOTIFICATIONS_KEY in dashboard .env");
    return res.redirect("/dashboard/notifications");
  }

  try {
    const payload = { title, body, send_to_all: shouldSendToAll };
    if (!shouldSendToAll) payload.recipient_user_ids = recipients;
    const result = await backendApi.createAppAnnouncement(payload, DASHBOARD_NOTIFICATIONS_KEY);
    setFlash(req, "success", `Announcement sent. Created notifications: ${result.created || 0}`);
  } catch (error) {
    setApiErrorFlash(req, res, error);
  }
  return res.redirect("/dashboard/notifications");
};

const showSliders = async (req, res) => {
  try {
    const [sliders, jobs] = await Promise.all([
      backendApi.fetchHomeSliders(),
      backendApi.fetchJobPostings(),
    ]);
    return renderDashboardPage(res, "dashboard/sliders", {
      activePage: "sliders",
      sliders,
      jobs,
    });
  } catch (error) {
    setApiErrorFlash(req, res, error);
    return renderDashboardPage(res, "dashboard/sliders", {
      activePage: "sliders",
      sliders: [],
      jobs: [],
    });
  }
};

const addSlider = async (req, res) => {
  const jobId = String(req.body.jobId || "").trim();
  if (!jobId || !req.file) {
    setFlash(req, "error", "Job and image are required.");
    return res.redirect("/dashboard/sliders");
  }
  try {
    await withAuthRetry(req, async ({ accessToken, internalKey }) => {
      const uploaded = await backendApi.uploadSliderImage(accessToken, req.file, internalKey);
      await backendApi.createHomeSlider(
        accessToken,
        { job_id: jobId, image_url: uploaded.url },
        internalKey,
      );
    });
    setFlash(req, "success", "Slider added successfully.");
  } catch (error) {
    setApiErrorFlash(req, res, error);
  }
  return res.redirect("/dashboard/sliders");
};

const deleteSlider = async (req, res) => {
  try {
    await withAuthRetry(req, ({ accessToken, internalKey }) =>
      backendApi.deleteHomeSlider(req.params.sliderId, accessToken, internalKey),
    );
    setFlash(req, "success", "Slider deleted successfully.");
  } catch (error) {
    setApiErrorFlash(req, res, error);
  }
  return res.redirect("/dashboard/sliders");
};

module.exports = {
  showOverview,
  showUsers,
  showVerifications,
  decidePracticeLicense,
  decideAccreditedCourse,
  showJobs,
  updateJobStatus,
  deleteJob,
  showNotifications,
  sendAppAnnouncement,
  showSliders,
  addSlider,
  deleteSlider,
};
