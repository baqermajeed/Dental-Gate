const backendApi = require("../services/backendApiService");
const { verifyLocalAdmin } = require("../config/adminConfig");

const showLoginPage = (req, res) => {
  if (req.session.user) {
    return res.redirect("/dashboard");
  }

  return res.render("auth/login", {
    title: "Login",
  });
};

const login = async (req, res) => {
  const { username, password } = req.body;
  if (!username?.trim() || !password) {
    req.session.flash = {
      type: "error",
      message: "اسم المستخدم وكلمة المرور مطلوبان.",
    };
    return res.redirect("/login");
  }

  if (!verifyLocalAdmin(username.trim(), password)) {
    req.session.flash = {
      type: "error",
      message: "اسم المستخدم أو كلمة المرور غير صحيحة.",
    };
    return res.redirect("/login");
  }

  req.session.user = {
    id: "dashboard-admin",
    phone: "dashboard-admin",
    email: "admin@dentalgate.internal",
    name: "Dashboard Admin",
    role: "admin",
  };
  req.session.tokens = null;

  try {
    const tokens = await backendApi.adminLogin(username.trim(), password);
    req.session.tokens = {
      accessToken: tokens.access_token,
      refreshToken: tokens.refresh_token,
    };
    const me = await backendApi.getMe(req.session.tokens.accessToken);
    req.session.user = {
      id: me.id,
      phone: me.phone,
      email: me.email,
      name: me.name,
      role: me.role,
    };
  } catch (error) {
    const is404 = String(error.message).includes("404");
    if (!is404) {
      req.session.flash = {
        type: "error",
        message: error.message,
      };
      req.session.user = null;
      return res.redirect("/login");
    }
  }

  req.session.flash = {
    type: "success",
    message: "تم تسجيل الدخول بنجاح.",
  };
  return res.redirect("/dashboard");
};

const logout = (req, res) => {
  req.session.destroy(() => {
    res.redirect("/login");
  });
};

module.exports = {
  showLoginPage,
  login,
  logout,
};
