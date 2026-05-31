const backendApi = require("../services/backendApiService");

const ADMIN_API_DEPLOY_HINT =
  "الباكند على السيرفر قديم ولا يحتوي مسارات admin-dashboard. " +
  "ارفع آخر نسخة Backend من GitHub ثم أعد تشغيل uvicorn/systemd. " +
  `الدومين: ${backendApi.BACKEND_BASE_URL}`;

const checkAdminApiMiddleware = async (req, res, next) => {
  try {
    await backendApi.checkAdminApiHealth();
    res.locals.adminApiReady = true;
    res.locals.adminApiWarning = null;
  } catch {
    res.locals.adminApiReady = false;
    res.locals.adminApiWarning = ADMIN_API_DEPLOY_HINT;
  }
  return next();
};

module.exports = checkAdminApiMiddleware;
