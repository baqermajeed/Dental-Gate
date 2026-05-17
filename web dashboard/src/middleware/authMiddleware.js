const ensureAuthenticated = (req, res, next) => {
  if (req.session.user && req.session.tokens?.accessToken) {
    return next();
  }

  req.session.flash = {
    type: "error",
    message: "Please login first.",
  };
  return res.redirect("/login");
};

module.exports = ensureAuthenticated;
