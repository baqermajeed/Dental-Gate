const backendApi = require("../services/backendApiService");

const ensureAccessToken = async (req) => {
  const tokens = req.session.tokens;
  if (!tokens?.accessToken) {
    throw new Error("Session expired. Please login again.");
  }
  return tokens.accessToken;
};

const withAuthRetry = async (req, action) => {
  try {
    const accessToken = await ensureAccessToken(req);
    return await action(accessToken);
  } catch (error) {
    if (!String(error.message).includes("status: 401")) {
      throw error;
    }

    const refreshValue = req.session.tokens?.refreshToken;
    if (!refreshValue) {
      throw new Error("Session expired. Please login again.");
    }

    const refreshed = await backendApi.refreshToken(refreshValue);
    req.session.tokens = {
      accessToken: refreshed.access_token,
      refreshToken: refreshed.refresh_token,
    };
    return action(req.session.tokens.accessToken);
  }
};

const showDashboard = async (req, res) => {
  try {
    const [sliders, myJobs] = await Promise.all([
      backendApi.fetchHomeSliders(),
      withAuthRetry(req, (accessToken) => backendApi.fetchMyJobs(accessToken)),
    ]);

    res.render("dashboard/index", {
      title: "Dashboard",
      sliders,
      myJobs,
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
      myJobs: [],
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
    await withAuthRetry(req, async (accessToken) => {
      const upload = await backendApi.uploadSliderImage(accessToken, req.file);
      await backendApi.createHomeSlider(accessToken, {
        job_id: jobId.trim(),
        image_url: upload.url,
      });
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
