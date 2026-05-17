const backendApi = require("../services/backendApiService");

const showLoginPage = (req, res) => {
  if (req.session.user) {
    return res.redirect("/dashboard");
  }

  return res.render("auth/login", {
    title: "Login",
    backendBaseUrl: backendApi.BACKEND_BASE_URL,
    pendingPhone: req.session.pendingPhone || "",
  });
};

const requestOtp = async (req, res) => {
  const { phone } = req.body;
  if (!phone?.trim()) {
    req.session.flash = { type: "error", message: "Phone number is required." };
    return res.redirect("/login");
  }

  try {
    await backendApi.requestOtp(phone);
    req.session.pendingPhone = phone.trim();
    req.session.flash = {
      type: "success",
      message: "OTP sent successfully. Enter the code to continue.",
    };
    return res.redirect("/login");
  } catch (error) {
    req.session.flash = {
      type: "error",
      message: error.message,
    };
    return res.redirect("/login");
  }
};

const verifyOtp = async (req, res) => {
  const { code, phone } = req.body;
  const targetPhone = phone?.trim() || req.session.pendingPhone;

  if (!targetPhone || !code?.trim()) {
    req.session.flash = {
      type: "error",
      message: "Phone number and OTP code are required.",
    };
    return res.redirect("/login");
  }

  try {
    const verification = await backendApi.verifyOtp(targetPhone, code);
    if (!verification?.account_exists || !verification?.token) {
      req.session.flash = {
        type: "error",
        message: "This phone has no account on backend. Create account in app first.",
      };
      return res.redirect("/login");
    }

    req.session.tokens = {
      accessToken: verification.token.access_token,
      refreshToken: verification.token.refresh_token,
    };

    const me = await backendApi.getMe(req.session.tokens.accessToken);
    req.session.user = {
      id: me.id,
      phone: me.phone,
      email: me.email,
      name: me.name,
      role: me.role,
    };

    req.session.pendingPhone = targetPhone;
    req.session.flash = {
      type: "success",
      message: "Logged in via backend successfully.",
    };
    return res.redirect("/dashboard");
  } catch (error) {
    req.session.flash = { type: "error", message: error.message };
    return res.redirect("/login");
  }
};

const logout = (req, res) => {
  req.session.destroy(() => {
    res.redirect("/login");
  });
};

module.exports = {
  showLoginPage,
  requestOtp,
  verifyOtp,
  logout,
};
