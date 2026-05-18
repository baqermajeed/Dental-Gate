const backendApi = require("../services/backendApiService");
const { DASHBOARD_INTERNAL_KEY } = require("../config/adminConfig");

const resolveAuth = async (req) => {
  const accessToken = req.session.tokens?.accessToken;
  if (accessToken) {
    return { accessToken, internalKey: null };
  }
  if (DASHBOARD_INTERNAL_KEY) {
    return { accessToken: null, internalKey: DASHBOARD_INTERNAL_KEY };
  }
  throw new Error(
    "انتهت الجلسة أو لم يُضبط مفتاح لوحة التحكم (DASHBOARD_INTERNAL_KEY). انشر تحديث الباكند أو أضف المفتاح في .env.",
  );
};

const withAuthRetry = async (req, action) => {
  const auth = await resolveAuth(req);
  try {
    return await action(auth);
  } catch (error) {
    if (!String(error.message).includes("status: 401") || !auth.accessToken) {
      throw error;
    }

    const refreshValue = req.session.tokens?.refreshToken;
    if (!refreshValue) {
      throw new Error("انتهت الجلسة. سجّل الدخول مرة أخرى.");
    }

    const refreshed = await backendApi.refreshToken(refreshValue);
    req.session.tokens = {
      accessToken: refreshed.access_token,
      refreshToken: refreshed.refresh_token,
    };
    return action({
      accessToken: req.session.tokens.accessToken,
      internalKey: null,
    });
  }
};

const showDashboard = async (req, res) => {
  try {
    const [sliders, jobs] = await Promise.all([
      backendApi.fetchHomeSliders(),
      backendApi.fetchJobPostings(),
    ]);

    res.render("dashboard/index", {
      title: "Dashboard",
      sliders,
      jobs,
      backendBaseUrl: backendApi.BACKEND_BASE_URL,
    });
  } catch (error) {
    if (String(error.message).includes("Session expired")) {
      req.session.user = null;
      req.session.tokens = null;
      req.session.flash = { type: "error", message: "Session expired. Please login again." };
      return res.redirect("/login");
    }

    req.session.flash = { type: "error", message: error.message };
    return res.render("dashboard/index", {
      title: "Dashboard",
      sliders: [],
      jobs: [],
      backendBaseUrl: backendApi.BACKEND_BASE_URL,
    });
  }
};

const addSlider = async (req, res) => {
  const { jobId } = req.body;

  if (!jobId?.trim() || !req.file) {
    req.session.flash = {
      type: "error",
      message: "Job selection and image file are required.",
    };
    return res.redirect("/dashboard");
  }

  try {
    await withAuthRetry(req, async ({ accessToken, internalKey }) => {
      const upload = await backendApi.uploadSliderImage(
        accessToken,
        req.file,
        internalKey,
      );
      await backendApi.createHomeSlider(
        accessToken,
        {
          job_id: jobId.trim(),
          image_url: upload.url,
        },
        internalKey,
      );
    });

    req.session.flash = {
      type: "success",
      message: "Slider published successfully to backend.",
    };
    return res.redirect("/dashboard");
  } catch (error) {
    req.session.flash = {
      type: "error",
      message: error.message,
    };
    return res.redirect("/dashboard");
  }
};

module.exports = {
  showDashboard,
  addSlider,
};
