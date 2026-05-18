const ensureAuthenticated = (req, res, next) => {
  if (req.session.user?.role === "admin") {
    return next();
  }

  req.session.flash = {
    type: "error",
    message: req.session.user
      ? "هذا الحساب ليس حساب مدير."
      : "يرجى تسجيل الدخول أولاً.",
  };
  return res.redirect("/login");
};

module.exports = ensureAuthenticated;
