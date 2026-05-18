const ADMIN_USERNAME = (process.env.DASHBOARD_ADMIN_USERNAME || "admin").trim();
const ADMIN_PASSWORD = process.env.DASHBOARD_ADMIN_PASSWORD || "admin12345";
const DASHBOARD_INTERNAL_KEY = (
  process.env.DASHBOARD_INTERNAL_KEY ||
  process.env.INTERNAL_DASHBOARD_KEY ||
  ""
).trim();

const verifyLocalAdmin = (username, password) => {
  return username.trim() === ADMIN_USERNAME && password === ADMIN_PASSWORD;
};

module.exports = {
  ADMIN_USERNAME,
  DASHBOARD_INTERNAL_KEY,
  verifyLocalAdmin,
};
